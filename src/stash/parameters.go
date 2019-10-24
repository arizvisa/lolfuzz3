package main

/*
    TODO:
    Some of the parameters that are parsed here can be defaulted to something
    else. The "-endpoint" option for example can default to "127.0.0.1". Even
    better as since this is part of lolfuzz, we can come up with default
    values for the secret and access keys.

    The "-force" option doesn't actually work. Once this gets tested against
    a live server, we'll be able to see what error message comes back in
    order to determine how to proceed.
*/

import (
    "os"
    "fmt"
    "flag"
    "strconv"
    "strings"
    "github.com/op/go-logging"
    JJ "github.com/cloudfoundry-attic/jibber_jabber"
)

const (
    DefaultLanguage = "en-US"
)

func Usage(name string, params map[string]interface{}) *flag.FlagSet {
    var res *flag.FlagSet

    // Construct the FlagSet containing available parameters
    res = flag.NewFlagSet(name, flag.ExitOnError)
    res.BoolVar(params["help"].(*bool), "help", false, "display usage of the command")

    res.StringVar(params["log-level"].(*string), "log-level", "WARNING", "log level")
    res.StringVar(params["log-file"].(*string), "log-file", "", "log file")

    res.BoolVar(params["force"].(*bool), "force", false, "overwrite any files that exist")
    res.StringVar(params["fields"].(*string), "fields", DefaultFields, "a comma-separated list of fields to emit")

    res.StringVar(params["name"].(*string), "name", "", "the filename to use when storing the file")
    res.StringVar(params["bucket"].(*string), "bucket", "", "the bucket to store the file into")

    res.BoolVar(params["useSSL"].(*bool), "useSSL", false, "use SSL when connecting to the endpoint")
    res.StringVar(params["endpoint"].(*string), "endpoint", "", "tne endpoint containing the bucket to store the file at (default port 9000)")
    res.StringVar(params["access-key"].(*string), "access-key", os.Getenv("MINIO_ACCESS_KEY"), "access key for authentication to the bucket")
    res.StringVar(params["secret-key"].(*string), "secret-key", os.Getenv("MINIO_SECRET_KEY"), "secret key for authentication to the bucket")

    res.StringVar(params["Content-Type"].(*string), "content-type", "", "the content-type of the file (auto-detected)")
    res.StringVar(params["Content-Encoding"].(*string), "content-encoding", "", "the content-encoding of the file (auto-detected)")
    res.StringVar(params["Content-Disposition"].(*string), "content-disposition", "", "the content-disposition of the file")
    res.StringVar(params["Content-Language"].(*string), "content-language", "", "the content-language of the file (current locale)")
    res.StringVar(params["Cache-Control"].(*string), "cache-control", "", "the cache-control of the file to upload")

    return res
}

func UsageError(f *flag.FlagSet, command, format string, a ...interface{}) {
    if format != "" {
        fmt.Fprintf(f.Output(), format, a...)
    }
    fmt.Fprintf(f.Output(), "Usage: %s [OPTION]... FILE [PutOptions]\n", command)
    f.PrintDefaults()
}

func ProcessParameters(command string) (string, []string) {
    var loggingLevel, loggingFilename, parameterFields string

    /// Build our FlagSet containing our parameters
    helpQ := false
    flags := Usage(command, map[string]interface{} {
        "help": &helpQ,

        "log-level": &loggingLevel,
        "log-file": &loggingFilename,

        "force": &Parameters.force,
        "fields": &parameterFields,

        "name": &Parameters.name,
        "bucket": &Parameters.bucket,

        "useSSL": &Parameters.useSSL,
        "endpoint": &Parameters.endpoint,
        "access-key": &Parameters.accessKey,
        "secret-key": &Parameters.secretKey,

        "Content-Type": &Parameters.options.ContentType,
        "Content-Encoding": &Parameters.options.ContentEncoding,
        "Content-Disposition": &Parameters.options.ContentDisposition,
        "Content-Language": &Parameters.options.ContentLanguage,
        "Cache-Control": &Parameters.options.CacheControl,
    })

    // and then parse them
    flags.Parse(os.Args[1:])

    /// First process the most important arguments
    if helpQ {
        UsageError(flags, command, "")
        os.Exit(0)
    }

    // process the logging options that we received
    loglevel := logging.WARNING
    if level, err := logging.LogLevel(loggingLevel); err != nil {
        valid_levels := []string{"debug", "info", "notice", "warning", "error"}
        UsageError(flags, command, "The argument to the -log-level parameter must be one of: %s\n\n", strings.Join(valid_levels, ", "))
        os.Exit(1)

    } else if loggingLevel != "" {
        Log.Debugf("Using log level %d", level)
        loglevel = level
    }

    if loggingFilename != "" {
        if backend, err, F := SetupLog_File(loglevel, loggingFilename); err != nil {
            Log.Fatalf("Error setting up log backend for file: %s", err)

        } else {
            Log.SetBackend(backend)
            LogDestructor = F
        }
    } else {
        backend := SetupLog_Default(loglevel)
        Log.SetBackend(backend)
        LogDestructor = func(){}
    }

    /// Check the existence of required parameters
    if Parameters.endpoint == "" {
        UsageError(flags, command, "An address must be provided to -endpoint.\n\n")
        os.Exit(1)
    }

    if Parameters.bucket == "" {
        UsageError(flags, command, "A bucket name must be provided to -bucket.\n\n")
        os.Exit(1)
    }

    if len(flags.Args()) == 0 && Parameters.name == "" {
        UsageError(flags, command, "A file name must be provided to -name if reading from standard input.\n\n")
        os.Exit(1)
    }

    if parameterFields == "" {
        UsageError(flags, command, "At list one field name must be provided to the -fields parameter.\n\n")
        os.Exit(1)
    }

    // and that they're are of a valid format
    Log.Debugf("Validating %d parameters: %v", len(os.Args), os.Args)
    if strings.Count(Parameters.endpoint, ":") > 1 {
        UsageError(flags, command, "Address must be formatted as address:port. If port is not specified then 9000 will be assumed.\n\n")
        os.Exit(1)
    }

    // check if stdin was passed because if it was, then we need a name as we're
    // unable to automatically determine it
    if Parameters.name == "" {
        args := flags.Args()
        if len(args) < 1 || flags.Args()[0] == "-" {
            UsageError(flags, command, "A file name must be provided to -name if reading from standard input.\n\n")
            os.Exit(1)
        }
    }

    fields := []string{}
    for _, field := range strings.Split(parameterFields, ",") {
        fields = append(fields, strings.ToLower(field))
    }
    Parameters.fields = fields

    /// Re-format parameters that are an incomplete format, or that need to be
    /// initialized to something.
    if strings.Count(Parameters.endpoint, ":") == 0 {
        Log.Infof("Using default port %d for endpoint: %s:%d", 9000, Parameters.endpoint, 9000)
        Parameters.endpoint = fmt.Sprintf("%s:%d", Parameters.endpoint, 9000)
    }

    if Parameters.options.ContentLanguage == "" {
        if lang, err := JJ.DetectIETF(); err != nil {
            Log.Warningf("Unable to detect language (will use %s): %s", strconv.Quote(DefaultLanguage), err)
            Parameters.options.ContentLanguage = DefaultLanguage
        } else {
            Log.Infof("Auto-detected Content-Language as %s", strconv.Quote(lang))
            Parameters.options.ContentLanguage = lang
        }
    }

    /// Figure out the path that the user specified
    args := flags.Args()

    // If there's no name or the name is "-" then empty it because it really
    // means to use standard input
    if len(args) == 0 || args[0] == "-" {
        return "", args[1:]
    }

    // Otherwise we can extract and return it as is
    name := args[0]
    return name, args[1:]
}
