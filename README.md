# iptv-channels
A small bash tool for updating M3U channel list.

## Concept
The tool is created around the concepts of *actions (create, update, etc...), steps* and *configurable notifications (e-mail, slack)*

The structure of the mentioned concept looks like:
```
├── helper.sh
├── main.sh
├── actions <directory>
│  │
│  ├── A_action <directory>
│  │  │
│  │  ├── asset <directory>
│  │  │   └── file.csv
│  │  │
│  │  ├── helper <directory>
│  │  │   └── step_helper.sh
│  │  │
│  │  ├── 1_step.sh
│  │  ├── 2_step.sh
│  │  ├── 3_step.sh
│  │  └── n_step.sh
│  │  
│  └── B_action <directory>
│     │
│     ├── 1_step.sh
│     ├── 2_step.sh
│     ├── 3_step.sh
│     └── n_step.sh
│
└── config.yml
```

`main.sh` & `helper.sh` are controller scripts (e.g. framework).


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
