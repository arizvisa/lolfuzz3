package main

/*
    TODO:
    This is using format-strings which aren't really documented yet. At some
    point it'd be cool to write a StringFormatter class which takes format-
    tokenized parameters. Something similar to "%{content-type}" so that way
    the user doesn't need to constantly xref with the list of available format
    strings.
*/

import (
    "os"
    "path"
    "bytes"
    "fmt"
    "time"
    "io"
    "io/ioutil"
    "strconv"
    "context"
    "net/http"
    "github.com/google/uuid"
)

const (
    SignatureHeaderSize = 0x200
    DefaultChunkSize = 0x200
    StringFloatPrecision = 3
)

type FormatParametersStructure struct {
    path string         // %P
    name string         // %N
    size int64          // %S

    mimetype string     // %M
    guid uuid.UUID      // %G

    ts time.Time        // %u = seconds, %U = nanoseconds, %t = time (24), %T = time, %d = date, %D = date/time (rfc3339)
}

func GetReaderFromPath(ctx context.Context, name string) (io.Reader, *FormatParametersStructure, error) {

    /// First check if the caller wants to read from stdin and then hand them
    /// off to the correct function
    if name == "" {
        return GetReaderFromStdin(ctx)
    }

    /// Otherwise we can simply open up the file w/o concern
    infile, err := os.Open(name)
    if err != nil {
        return nil, nil, err
    }

    // Now that we have a file handle, create a goro so that we can shut things
    // down if the caller tells us to
    go func(f *os.File) {
        <-ctx.Done()
        Log.Debugf("Trying to close file %s", strconv.Quote(f.Name()))
        if err := f.Close(); err != nil {
            Log.Warning(err)
        }
    }(infile)

    /// Ok, time to grab some attributes to populate our format parameters
    result := &FormatParametersStructure{}

    // Try and read some bytes to determine the signature
    Log.Debugf("Reading %d bytes from file for fingerprint", SignatureHeaderSize)
    data := make([]byte, SignatureHeaderSize)
    if n, err := infile.Read(data); err != nil {
        return nil, nil, err

    } else {
        Log.Infof("Pre-read %d bytes from reader for fingerprint", n)
    }

    // Figure it out using net/http
    Log.Debugf("Examining %d bytes to determine mime type", len(data))
    result.mimetype = http.DetectContentType(data)

    // Combine what we read with the original file so it looks like we didn't
    // tamper with it
    r := io.MultiReader(bytes.NewReader(data), infile)

    // Grab the fileinfo so we can figure out the size
    Log.Debugf("Grabbing the stats for file %s", strconv.Quote(infile.Name()))
    if fi, err := infile.Stat(); err == nil {
        Log.Infof("Found %d bytes in file", fi.Size())

        result.ts = fi.ModTime()
        result.size = fi.Size()

    // Welp...that didn't work
    } else {
        return nil, nil, err
    }

    /// Now we can read the regular attributes since those won't fail
    result.path = name
    result.name = path.Base(name)

    return r, result, nil
}

func GetReaderFromStdin(ctx context.Context) (io.Reader, *FormatParametersStructure, error) {

    infile := os.Stdin

    /// Despite ioutil.ReadAll already closing the file, startup a goro so that
    /// we can close it explicitly when the context we get is done.
    go func(f *os.File) {
        <-ctx.Done()
        Log.Debugf("Trying to close file %s", strconv.Quote(f.Name()))
        if err := f.Close(); err != nil {
            Log.Warning(err)
        }
    }(infile)

    /// Read contents from standard input
    Log.Debugf("Reading data from standard input")
    data, err := ioutil.ReadAll(infile)
    if err != nil {
        return nil, nil, fmt.Errorf("Unable to read standard input: %s", err)
    }
    Log.Infof("Read %d bytes from standard input", len(data))

    /// Grab out properties that can result in errors so that we can terminate
    /// ahead of time
    result := &FormatParametersStructure{}

    // Generate a new uuid for this file
    result.guid = uuid.New()

    // Now we can populate the rest of our structure
    result.ts = time.Now()
    result.path = ""
    result.name = ""
    result.mimetype = http.DetectContentType(data)
    result.size = int64(len(data))

    return bytes.NewReader(data), result, nil
}

func FormatTypeFromParameters(in rune, params *FormatParametersStructure) string {
    switch in {
    case '%':
        return string(in)

    /// File attributes
    case 'N':
        // file name
        return params.name
    case 'P':
        // path to file
        return params.path
    case 'S':
        // size
        return strconv.FormatInt(params.size, 10)

    /// Miscellaneous attributes
    case 'M':
        // mime-type
        return params.mimetype
    case 'G':
        // random guid
        return params.guid.String()

    /// time-related formats
    case 'u':
        // seconds
        ts := params.ts.Unix()
        return strconv.FormatInt(ts, 10)
    case 'U':
        // nanoseconds (float)
        ts := float64(params.ts.UnixNano()) / 1e9
        return strconv.FormatFloat(ts, 'f', StringFloatPrecision, 64)
    case 't':
        // time
        return params.ts.Format("15:04:05")
    case 'T':
        // time
        return params.ts.Format("03:04:05 PM")
    case 'd':
        // date
        return params.ts.Format("2006-01-02")
    case 'D':
        // date/time (rfc3339)
        ts := params.ts
        return ts.Format(time.RFC3339)

    /// Invalid format characters
    default:
        return "%" + string(in)
    }
}

func FormatNameFromParameters(format string, params *FormatParametersStructure) string {

    input := make(chan rune)
    go func(s string) {
        for _, ch := range s {
            input <- ch
        }
        close(input)
    }(format)

    // Iterate through our string
    result := ""
    for {

        // Read a character from our string
        ch, ok := <-input
        if !ok {
            break
        }

        // Seek for a % character
        switch ch {
        case '%':
            ch = <-input
            result += FormatTypeFromParameters(ch, params)

        // Otherwise just append the character to our result
        default:
            result += string(ch)
        }
    }

    // That's all folks!
    return result
}
