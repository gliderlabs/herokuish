package main

import (
	"log"
	"os"
	"strings"

	"github.com/progrium/go-basher"
)

func assert(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	var bashPath string
	if strings.Contains(os.Getenv("SHELL"), "bash") {
		bashPath = os.Getenv("SHELL")
	} else {
		bashPath = "/bin/bash"
	}
	bash, err := basher.NewContext(bashPath, os.Getenv("DEBUG") != "")
	assert(err)
	bash.HandleFuncs(os.Args)

	bash.Source("bash/herokuish.bash", Asset)
	bash.Source("bash/fn.bash", Asset)
	bash.Source("bash/cmd.bash", Asset)
	bash.Source("bash/buildpack.bash", Asset)
	bash.Source("bash/procfile.bash", Asset)
	bash.Source("bash/slug.bash", Asset)
	bash.CopyEnv()
	status, err := bash.Run("main", os.Args[1:])
	assert(err)
	os.Exit(status)
}
