from time import sleep
from fabric.api import parallel, task
import fabric


@task
@parallel
def run():
    """Immediately start a puppet run, force-stopping any currently running puppet run."""
    stop()
    fabric.api.run('puppet agent --enable', warn_only=True)
    fabric.api.run('puppet agent --no-daemonize --onetime --verbose', warn_only=True)
    fabric.api.run('service puppet start')


@task
@parallel
def stop():
    # Stop the service
    # added warn_only as was getting random 'Fatal error' at this point
    fabric.api.run('service puppet stop', warn_only=True)

    # pgrep puppet -c returns the number of puppet processes that are
    # running. If it isn't 0, we need to pkill them
    if not fabric.api.run('pgrep puppet -c', warn_only=True).startswith('0'):
        fabric.api.run('pkill puppet', warn_only=True)
        sleep(5)

        # If 5 seconds wasn't enough to kill the active runs, continue
        # pkill'ing and waiting 1 second each iteration
        while not fabric.api.run('pgrep puppet -c', warn_only=True).startswith("0"):
            print 'Puppet is still running, trying to kill it again'
            fabric.api.run('pkill puppet', warn_only=True)
            sleep(1)
