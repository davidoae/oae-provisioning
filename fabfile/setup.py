from fabric.api import env, task


@task
def setup():
    env.roledefs = {'app':['root@37.153.99.4'],'db':['root@37.153.97.28'],'mq':['root@37.153.98.68'],'puppet':['root@37.153.96.40']}
    env.puppet_internal_ip = '10.224.16.4'
    env.puppet_host = 'root@37.153.96.40'
    env.provision_groups = [{'names':['db0','mq0'],'hosts':['root@37.153.97.28','root@37.153.98.68']},{'names':['app0'],'hosts':['root@37.153.99.4']}]
