package main

import (
    "fmt"
    "os"
    "time"
    "github.com/op/go-logging"
)

var (
    format = logging.MustStringFormatter(
        `%{time} (%{module}) %{shortfile} [%{level}] %{message}`,
    )
)

func SetupLog_DefaultFormatter(output logging.Backend) logging.Backend {
    return logging.NewBackendFormatter(output, format)
}

func SetupLog_DefaultBackend() logging.Backend {
    return logging.NewLogBackend(os.Stderr, "", 0)
}

func SetupLog_FileBackend(filename string) (func(), logging.Backend, error) {

    // First try and open the file in append-only mode
    Log.Debugf("Trying to open file %s for log output", filename)
    f, err := os.OpenFile(filename, os.O_SYNC|os.O_WRONLY|os.O_APPEND, os.ModeAppend)

    // If we were successful, then return our file along with its backend
    if err == nil {
        fmt.Fprintf(f, "------------- log file opened at %s -------------\n", time.Now().String())
        return func() {
            fmt.Fprintf(f, "============= log file closed at %s =============\n", time.Now().String())
            f.Close()
        }, logging.NewLogBackend(f, "", 0), nil
    }

    // If we failed because the file exists, then try and create it
    if os.IsNotExist(err) {
        Log.Debugf("Creating new log file %s for output", filename)
        f, err = os.OpenFile(filename, os.O_SYNC|os.O_WRONLY|os.O_CREATE, os.ModeAppend)
    }

    // If we were successful, then we can use this file for our backend
    if err == nil {
        fmt.Fprintf(f, "------------- log file created at %s -------------\n", time.Now().String())
        return func() {
            fmt.Fprintf(f, "============= log file closed at %s =============\n", time.Now().String())
            f.Close()
        }, logging.NewLogBackend(f, "", 0), nil
    }

    // If some error happened, then return it since we can't do anything with it
    return nil, nil, err
}

func SetupLog_Initialize(level logging.Level) {
    logging.SetFormatter(format)
    logging.SetLevel(level, "")
}

func SetupLog_Default(level logging.Level) logging.LeveledBackend {
    output := SetupLog_DefaultBackend()
    formatter := SetupLog_DefaultFormatter(output)
    leveled := logging.AddModuleLevel(formatter)
    leveled.SetLevel(level, Command)
    logging.SetBackend(leveled, formatter)
    return leveled
}

func SetupLog_File(level logging.Level, filename string) (logging.LeveledBackend, error, func()) {

    // Try and setup the log file
    if f, output, err := SetupLog_FileBackend(filename); err == nil {
        formatter := SetupLog_DefaultFormatter(output)
        leveled := logging.AddModuleLevel(output)
        leveled.SetLevel(level, Command)
        logging.SetBackend(leveled, formatter)
        return leveled, nil, f

    // Didn't seem to work
    } else {
        return nil, err, func(){}
    }
}
