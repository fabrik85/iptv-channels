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
___
### With Docker Compose (Local Development):

  1. Start the container:
     ```bash
     docker-compose up -d
     ```

  2. Step inside the running container:
     ```bash
     docker-compose exec iptv bash
     ```

  5. Execute an action inside the container:
     ```bash
     ./main.sh --action=create --dryrun --debug
     ```

___
### With Docker:
  1. Create an empty directory called `iptv` under your `$HOME` directory.
     ```bash
     mkdir $HOME/iptv
     ```

     Content will be created inside `${HOME}/iptv` directory.

  2. Build docker image.
     ```bash
     docker build --tag iptv --file ${PWD}/docker/Dockerfile .
     ```

  3. Mount `iptv` under the same location in docker.
     ```bash
     docker run -v ${HOME}/iptv:/root/iptv --rm --name iptv... iptv:latest
     ```

___
### Without Docker:
You need have a Linux machine in order to run without docker.

  1. Create an empty directory called `iptv` under your `$HOME` directory.
     ```bash
      mkdir ${HOME}/iptv
      ```

  2. Execute an action.
     ```bash
     ./main.sh --action=create_hls
     ```

     Content will be created inside `${HOME}/iptv` directory.</pre>
