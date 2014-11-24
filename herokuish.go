package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/progrium/go-basher"
	"gopkg.in/yaml.v2"
)

func assert(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func YamlKeys(args []string) int {
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)
	var m interface{}
	assert(yaml.Unmarshal(bytes, &m))
	for _, arg := range args {
		if m == nil {
			break
		}
		m = m.(map[interface{}]interface{})[arg]
	}
	n, ok := m.(map[interface{}]interface{})
	if ok {
		for key := range n {
			fmt.Printf("%s\n", key)
		}
	}
	return 0
}

func YamlGet(args []string) int {
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)
	var m interface{}
	assert(yaml.Unmarshal(bytes, &m))
	for _, arg := range args {
		if m == nil {
			break
		}
		m = m.(map[interface{}]interface{})[arg]
	}
	switch val := m.(type) {
	case string:
		println(val)
	case map[interface{}]interface{}:
		for key := range val {
			fmt.Printf("%s=%s\n", key, val[key])
		}
	case []interface{}:
		for _, v := range val {
			fmt.Printf("%s\n", v)
		}
	}
	return 0
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
	bash.ExportFunc("yaml-keys", YamlKeys)
	bash.ExportFunc("yaml-get", YamlGet)
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
