#!/usr/bin/env python3
import json
import sys
import os
import apprise

def file_env(var: str, default: str = None) -> str:
    """Return value of a environment variable that can also be defined as a file with _FILE as ending

    Args:
        var (str): the environment variable name
        default (str, optional): A default value. Defaults to None.

    Returns:
        str | None: the value of the variable. If "{var}_FILE" is defined the value of the file. If both are not defined the default
    """
    file_var = os.getenv(var + "_FILE")
    res = os.getenv(var, default)
    if file_var and os.path.isfile(file_var) :
        with open(file_var, "r") as file:
            res = "\n".join(file.readlines())
    return res


def main():
    run_record = json.load(sys.stdin)
    if run_record["succeeded"]:
        type = apprise.NotifyType.SUCCESS
        title = f"{run_record['job']['name']} succeeded"
    else:
        type = apprise.NotifyType.FAILURE
        title = f"{run_record['job']['name']} failed"

    body = f"""
Stdout:
```
{run_record['stdout']}
```
Stderr:
```
{run_record['stderr']}
```
    """

    apobj = apprise.Apprise()

    # Defaults
    global_config = file_env("APPRISE_NOTIFY_CONFIG")
    global_url = file_env("APPRISE_NOTIFY_URL")
    global_tag = os.getenv("APPRISE_NOFITY_TAG", default="all") 

    # Overrides per job
    job_id = os.getenv("JOB_ID", default='')
    config = file_env(f"APPRISE_NOTIFY_CONFIG{job_id}", global_config)
    url = file_env(f"APPRISE_NOTIFY_URL{job_id}", global_url)
    tag = os.getenv(f"APPRISE_NOFITY_TAG{job_id}", global_tag)

    if config:
        apconfig = apprise.AppriseConfig()
        apconfig.add(config)
        apobj.add(apconfig)
    if url:
        apobj.add(url, tag=tag)

    apobj.notify(body,title=title,notify_type=type,body_format=apprise.NotifyFormat.MARKDOWN, tag=tag)

if __name__ == '__main__':
    main()
