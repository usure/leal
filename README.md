# leal

leal is a small http server written in ruby. [wip]

--- todo
  * [x] linking
  * [x] directory structure
  * [x] content-type detector
  * [x] serve up "index.html" if it exists
  * [x] directory listing
  * [x] logging functionality
  * [x] command line interface (optparse)
  * [x] php support (phpinfo works. I doubt POST/GET works with it.)
  * [x] make GET with forms work
  * [ ] inline php support (important)
  * [ ] make POST work
  * [ ] probably other things


### dependencies

* php5 (if you want php support)
* php5-cgi (THIS IS NEEDED if you want php support)

### guide
(store the files you want to serve up in a directory named "html")
(before running these commands please change the "host" & "port" values to your liking in leal.rb)
```
$ ruby leal.rb # run this command or
$ ruby leal.rb -h $HOSTNAME -p $PORT -l [$LOG_FILE or none] run this command
$ ruby leal -h # for help
```
### license
![](http://i.imgur.com/HdsLqoL.png)

copyfarleft
