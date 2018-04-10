from fabric.api import local, task
from fabric.network import disconnect_all
import imp
import time
import types


@task
def bootstrap(environment, machine_names=None, yes=False):
    local('slapchop bootstrap -d %s %s' % (environment, get_slapchop_args(machine_names, yes)))

    print 'Sleeping 15 seconds to allow sshd time to start up'
    time.sleep(15)


@task
def fabric_setup(environment):
    local('slapchop fabric-setup -d %s' % environment)
    setup = imp.load_source('setup', 'fabfile/setup.py')
    setup.setup()


@task
def reboot(environment, machine_names=None, yes=False):
    local('slapchop reboot -d %s %s' % (environment, get_slapchop_args(machine_names, yes)))

    # Disconnect to purge cached ssh connections that were connected to these machines that we've rebooted
    disconnect_all()

    print 'Sleeping a way too long 90 seconds waiting for aws slow reboots'
    time.sleep(90)


def to_machine_array(machine_names=None):
    if machine_names == None:
        return None
    elif isinstance(machine_names, types.StringTypes):
        return machine_names.split(';')
    else:
        return machine_names


def get_slapchop_args(machine_names=None, yes=False):
    args = ''

    machine_names = to_machine_array(machine_names)
    if machine_names != None:
        args = '-i %s' % ' -i '.join(machine_names)

    if yes:
        args += ' -y'

    return args
