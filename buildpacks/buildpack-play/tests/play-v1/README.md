# Play Quick Start Guide

This guide will walk you through deploying a Play application on Deis.

## Usage

    $ deis create
    Creating application... done, created quinoa-macaroni
    Git remote deis added
    $ git push deis master
    Counting objects: 86, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (74/74), done.
    Writing objects: 100% (86/86), 91.96 KiB | 0 bytes/s, done.
    Total 86 (delta 13), reused 0 (delta 0)
    -----> Play! app detected
    -----> Installing OpenJDK 1.6... done
    -----> Installing Play! 1.3.0.....
    -----> done
    -----> Building Play! application...
           ~        _            _
           ~  _ __ | | __ _ _  _| |
           ~ | '_ | |/ _' | || |_|
           ~ |  __/|_|____|__ (_)
           ~ |_|            |__/
           ~
           ~ play! 1.3.0, https://www.playframework.com
           ~
           1.3.0
           Building Play! application at directory ./
           Resolving dependencies: .play/play dependencies ./ --forProd --forceCopy --silent -Duser.home=/tmp/build 2>&1
           ~ Resolving dependencies using /tmp/build/conf/dependencies.yml,
           ~
           ~
           ~ No dependencies to install
           ~
           ~ Done!
           ~
           Precompiling: .play/play precompile ./ --silent 2>&1
           Listening for transport dt_socket at address: 8000
           15:42:35,694 INFO  ~ Starting /tmp/build
           :: loading settings :: url = jar:file:/tmp/build/.play/framework/lib/ivy-2.3.0.jar!/org/apache/ivy/core/settings/ivysettings.xml
           15:42:36,791 INFO  ~ Precompiling ...
           Jan 30, 2015 3:42:39 PM org.codehaus.groovy.runtime.m12n.MetaInfExtensionModule newModule
           WARNING: Module [groovy-all] - Unable to load extension class [org.codehaus.groovy.runtime.NioGroovyMethods]
           15:42:46,273 INFO  ~ Done.
           ~ using java version "1.6.0_27"
    -----> Discovering process types
           Procfile declares types -> web
    -----> Compiled slug size is 84M

    -----> Building Docker image
    remote: Sending build context to Docker daemon 87.32 MB
    remote: build context to Docker daemon
    Step 0 : FROM deis/slugrunner
     ---> 7474b542af26
    Step 1 : RUN mkdir -p /app
     ---> Running in 15e5f7e98502
     ---> 1ef08045ea6c
    Removing intermediate container 15e5f7e98502
    Step 2 : WORKDIR /app
     ---> Running in d19670e296b0
     ---> 471fc8e5a374
    Removing intermediate container d19670e296b0
    Step 3 : ENTRYPOINT /runner/init
     ---> Running in b8458526e774
     ---> 2e360120165d
    Removing intermediate container b8458526e774
    Step 4 : ADD slug.tgz /app
     ---> 97cb51d6e197
    Removing intermediate container 0760260339ca
    Step 5 : ENV GIT_SHA 59303a00650091685e13cc055c3b9437ce4e7ff8
     ---> Running in 547ee6f35db3
     ---> aa496469ed62
    Removing intermediate container 547ee6f35db3
    Successfully built aa496469ed62
    -----> Pushing image to private registry

    -----> Launching...
           done, quinoa-macaroni:v2 deployed to Deis

           http://quinoa-macaroni.local3.deisapp.com

           To learn more, use `deis help` or visit http://deis.io

    To ssh://git@deis.local3.deisapp.com:2222/quinoa-macaroni.git
     * [new branch]      master -> master
    $ curl -s http://quinoa-macaroni.local3.deisapp.com
    Powered by Deis

## Additional Resources

* [Get Deis](http://deis.io/get-deis/)
* [GitHub Project](https://github.com/deis/deis)
* [Documentation](http://docs.deis.io/)
* [Blog](http://deis.io/blog/)
