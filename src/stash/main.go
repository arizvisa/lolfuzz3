package main

/*
    TODO:
    The default field names are hardcoded, and checked in more than one function.
    At some point what format.go gets rewritten to support StringFormatter-style
    syntax, this same field names can probably be used by the user when
    customizing what the output should look like.
*/

import (
    "os"
    "fmt"
    "bufio"
    "context"
    "strings"
    "strconv"
    "github.com/op/go-logging"
    "github.com/minio/minio-go"
)

const (
    Command = "stash"
    DefaultFields = "path,bucket,name,status,size"

    DefaultContentType = "application/octet-stream"
    EnvironmentUserAgent = "HTTP_USER_AGENT"
    EnvironmentSeparator = "IFS"
)

type parameterStructure struct {
    bucket, name string

    force bool
    fields []string

    endpoint string
    accessKey, secretKey string
    useSSL bool

    options minio.PutObjectOptions
}

var (
    Log *logging.Logger
    Parameters = parameterStructure{}
    LogDestructor func()
)

func main() {
    /// First initialize the default Log
    Log = logging.MustGetLogger(Command)
    SetupLog_Initialize(logging.WARNING)

    // and figure out our process name
    Arg0 := Command
    if len(os.Args) > 0 {
        Arg0 = os.Args[0]
    }

    // Now that we've figured out our process name, go ahead and process our arguments
    name, args := ProcessParameters(Arg0)
    defer LogDestructor()

    // then cross-check the fields that we were given
    if err := CheckAvailableFields(Parameters.fields); err != nil {
        Log.Fatalf("Error proceessing fields: %s", err)
    }

    // and fetch any metadata from the args that were leftover
    if err := CheckUserMetadata(args); err != nil {
        Log.Fatalf("Unable to parse metadata: %s", err)
    }
    formattedMetadata := ParseUserMetadata(args)

    /// Create our cleanup context that we can use if necessary
    ctx, cleanup := context.WithCancel(context.Background())
    defer cleanup()

    /// Now we can open up our file and figure some things out...
    reader, formatParameters, err := GetReaderFromPath(ctx, name)
    if err != nil {
        Log.Fatal(err)
    }

    // and use it to start assigning options provided by both the user and the file
    if Parameters.options.ContentType == "" {
        Parameters.options.ContentType = formatParameters.mimetype
    }

    // or to re-format the filename
    if Parameters.name == "" {
        Parameters.name = formatParameters.name
    } else {
        Parameters.name = FormatNameFromParameters(Parameters.name, formatParameters)
    }

    // and the metadata provided by the user
    UserMetadata := ReformatUserMetadata(formattedMetadata, formatParameters)

    /// Notify the user the options we're going to be using
    Log.Noticef("Filename: %s", Parameters.name)
    Log.Noticef("Content-Size: %d", formatParameters.size)

    NotifyPutObjectOptions(Parameters.options)

    if len(UserMetadata) > 0 {
        Log.Noticef("UserMetadata: %#v", UserMetadata)
    }

    Log.Infof("Ready to upload!")

    /// Okay, we should be good to go...so connect to our endpoint.
    Log.Noticef("Connecting to endpoint: %s", Parameters.endpoint)
    client, err := minio.New(Parameters.endpoint, Parameters.accessKey, Parameters.secretKey, Parameters.useSSL)
    if err != nil {
        Log.Fatalf("Unable to connect to endpoint %s: %s", Parameters.endpoint, err)
    }

    // Use the user-agent from the environment if it's defined
    if agent, ok := os.LookupEnv(EnvironmentUserAgent); ok {
        tuple := strings.SplitN(agent, "/", 2)
        product, version := tuple[0], tuple[1]
        client.SetAppInfo(product, version)
    }

    // Check to ensure the bucket exists
/*
    Log.Infof("Checking existence of bucket: %s", Parameters.bucket)
    if ok, err := client.BucketExists(Parameters.bucket); err != nil {
        Log.Fatalf("Error verifying bucket (%s): %s", Parameters.bucket, err)

    } else if !ok {
        Log.Fatalf("Bucket %s does not exist", Parameters.bucket)
    }
*/

    /// Finally we can use our reader to upload the file
    _ = bufio.NewReader(reader)
    status := ""
    n := formatParameters.size

    //n, err := client.PutObjectWithContext(ctx, Parameters.bucket, Parameters.name, r, formatParameters.size, Parameters.options)
    if err != nil {
        Log.Fatalf("Unable to upload file %s to %s: %s", name, Parameters.name, err)
        status = "error"

    // If the file size does not match what's expected, then warn the user
    } else if n != formatParameters.size {
        Log.Warningf("Uploading of file %s to %s was incomplete (%d <> %d)", name, Parameters.name, n, formatParameters.size)
        status = "incomplete"

    } else {
        status = "success"
    }

    /// Initialize the fields that our output will choose from
    result := GetAvailableFields(formatParameters)
    result["status"] = status
    result["size"] = strconv.FormatInt(n, 10)
    result["bucket"] = Parameters.bucket

    // Iterate through the fields actually collecting our values
    res := []string{}
    for _, name := range Parameters.fields {
        res = append(res, result[name])
    }

    // Figure out what separator to use
    if sep, ok := os.LookupEnv(EnvironmentSeparator); ok {
        fmt.Println(strings.Join(res, sep))
    } else {
        fmt.Println(strings.Join(res, "\t"))
    }

    /// Exit code is based on uploading the complete file or only partially
    if n != formatParameters.size {
        os.Exit(1)
    }
    os.Exit(0)
}

func CheckUserMetadata(metadata []string) error {

    for _, item := range metadata {
        if strings.Count(item, "=") != 1 {
            return fmt.Errorf("Item is not of the correct format (key=value): %s", strconv.Quote(item))
        }
    }

    return nil
}

func ParseUserMetadata(metadata []string) map[string]string {
    result := map[string]string{}

    // Iterate through each parameter
    for _, item := range metadata {
        tuple := strings.SplitN(item, "=", 2)
        key, value := tuple[0], tuple[1]
        result[key] = value
    }

    return result
}

func ReformatUserMetadata(metadata map[string]string, params *FormatParametersStructure) map[string]string {
    result := map[string]string{}
    for key, value := range metadata {
        result[key] = FormatNameFromParameters(value, params)
    }
    return result
}

func NotifyPutObjectOptions(options minio.PutObjectOptions) {

    if options.ContentType != "" {
        Log.Noticef("Content-Type: %s", strconv.Quote(options.ContentType))
    }
    if options.ContentEncoding != "" {
        Log.Noticef("Content-Encoding: %s", strconv.Quote(options.ContentEncoding))
    }
    if options.ContentDisposition != "" {
        Log.Noticef("Content-Disposition: %s", strconv.Quote(options.ContentDisposition))
    }
    if options.ContentLanguage != "" {
        Log.Noticef("Content-Language: %s", strconv.Quote(options.ContentLanguage))
    }
    if options.CacheControl != "" {
        Log.Noticef("Cache-Control: %s", strconv.Quote(options.CacheControl))
    }
}

func CheckAvailableFields(fields []string) error {
    available := []string{
        "name", "path", "bucket", "size", "status", "content-type", "guid",
    }

    // iterate through the specified fields
    for _, field := range fields {
        ok := false

        // iterate through the available fields looking for a match
        for _, item := range available {
            if item == field {
                ok = true
            }
        }

        // check if we didn't find a match
        if !ok {
            return fmt.Errorf("Requested field %s is not available", strconv.Quote(field))
        }
    }
    return nil
}

func GetAvailableFields(params *FormatParametersStructure) map[string]string {
    result := map[string]string{}

    // assign all fields with known values
    result["name"] = params.name
    result["path"] = params.path
    result["content-type"] = params.mimetype
    result["guid"] = params.guid.String()

    // except for "status", "size", and "bucket"
    result["status"] = ""
    result["size"] = ""
    result["bucket"] = ""

    return result
}
