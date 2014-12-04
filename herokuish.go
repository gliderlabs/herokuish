package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/progrium/go-basher"
	"gopkg.in/yaml.v2"
)

var Version string

func YamlKeys(args []string) int {
	bytes, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		log.Fatal(err)
	}
	var m interface{}
	err = yaml.Unmarshal(bytes, &m)
	if err != nil {
		log.Fatal(err)
	}
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
	if err != nil {
		log.Fatal(err)
	}
	var m interface{}
	err = yaml.Unmarshal(bytes, &m)
	if err != nil {
		log.Fatal(err)
	}
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
	os.Setenv("VERSION", Version)
	basher.Application(map[string]func([]string) int{
		"yaml-keys": YamlKeys,
		"yaml-get":  YamlGet,
	}, []string{
		"include/herokuish.bash",
		"include/fn.bash",
		"include/cmd.bash",
		"include/buildpack.bash",
		"include/procfile.bash",
		"include/slug.bash",
	}, Asset, true)
}
