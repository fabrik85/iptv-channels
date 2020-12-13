# iptv-channels
A small bash tool for updating M3U channel list.

# How to run it locally?

* With docker:
    * Create an empty directory called `iptv` under your `$HOME` directory.<pre>mkdir ${HOME}/iptv</pre>
    * Mount `iptv` under the same location in docker. <pre>docker run -v ${HOME}/iptv:/root/iptv --rm --name iptv... fabrik85/iptv-channels</pre>
    * Content will be created inside `${HOME}/iptv` directory.</pre>

* Without docker:
    * You need have `linux` machine in order to run without docker.
    * Create an empty directory called `iptv` under your `$HOME` directory.<pre>mkdir ${HOME}/iptv</pre>
    * Run your action. <pre>./main.sh --action=create_hls</pre>
    * Content will be created inside `${HOME}/iptv` directory.</pre>
