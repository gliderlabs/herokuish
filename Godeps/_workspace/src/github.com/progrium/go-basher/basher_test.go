package basher

import (
	"bytes"
	"strconv"
	"testing"
)

var bashpath = "/bin/bash"

var testScripts = map[string]string{
	"hello.sh":  `main() { echo "hello"; }`,
	"cat.sh":    `main() { cat; }`,
	"foobar.sh": `main() { echo $FOOBAR; }`,
}

func testLoader(name string) ([]byte, error) {
	return []byte(testScripts[name]), nil
}

func exportedFunc(args []string) int {
	status, err := strconv.Atoi(args[0])
	if err != nil {
		panic(err)
	}
	return status
}

func TestHelloStdout(t *testing.T) {
	bash, _ := NewContext(bashpath, false)
	bash.Source("hello.sh", testLoader)

	var stdout bytes.Buffer
	bash.Stdout = &stdout
	status, err := bash.Run("main", []string{})
	if err != nil {
		t.Fatal(err)
	}
	if status != 0 {
		t.Fatal("non-zero exit")
	}
	if stdout.String() != "hello\n" {
		t.Fatal("unexpected stdout:", stdout.String())
	}
}

func TestHelloStdin(t *testing.T) {
	bash, _ := NewContext(bashpath, false)
	bash.Source("cat.sh", testLoader)
	bash.Stdin = bytes.NewBufferString("hello\n")

	var stdout bytes.Buffer
	bash.Stdout = &stdout
	status, err := bash.Run("main", []string{})
	if err != nil {
		t.Fatal(err)
	}
	if status != 0 {
		t.Fatal("non-zero exit")
	}
	if stdout.String() != "hello\n" {
		t.Fatal("unexpected stdout:", stdout.String())
	}
}

func TestEnvironment(t *testing.T) {
	bash, _ := NewContext(bashpath, false)
	bash.Source("foobar.sh", testLoader)
	bash.Export("FOOBAR", "hello")

	var stdout bytes.Buffer
	bash.Stdout = &stdout
	status, err := bash.Run("main", []string{})
	if err != nil {
		t.Fatal(err)
	}
	if status != 0 {
		t.Fatal("non-zero exit")
	}
	if stdout.String() != "hello\n" {
		t.Fatal("unexpected stdout:", stdout.String())
	}
}

func TestFuncCallback(t *testing.T) {
	bash, _ := NewContext(bashpath, false)
	bash.ExportFunc("myfunc", exportedFunc)
	bash.SelfPath = "/bin/echo"

	var stdout bytes.Buffer
	bash.Stdout = &stdout
	status, err := bash.Run("myfunc", []string{"abc", "123"})
	if err != nil {
		t.Fatal(err)
	}
	if status != 0 {
		t.Fatal("non-zero exit")
	}
	if stdout.String() != ":: myfunc abc 123\n" {
		t.Fatal("unexpected stdout:", stdout.String())
	}
}

func TestFuncHandling(t *testing.T) {
	exit := make(chan int, 1)
	bash, _ := NewContext(bashpath, false)
	bash.Exiter = func(code int) {
		exit <- code
	}
	bash.ExportFunc("test-success", exportedFunc)
	bash.ExportFunc("test-fail", exportedFunc)

	bash.HandleFuncs([]string{"thisprogram", "::", "test-success", "0"})
	status := <-exit
	if status != 0 {
		t.Fatal("non-zero exit")
	}

	bash.HandleFuncs([]string{"thisprogram", "::", "test-fail", "2"})
	status = <-exit
	if status != 2 {
		t.Fatal("unexpected exit status:", status)
	}
}
