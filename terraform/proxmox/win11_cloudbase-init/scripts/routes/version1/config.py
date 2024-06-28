import os

class Config:
    PRIMARY_NODE = {'name': 'pve', 'url': os.getenv('PRIMARY_NODE_URL', 'http://10.11.1.181:6969')}
    SECONDARY_NODES = [
        {'name': 'pve2', 'url': os.getenv('SECONDARY_NODE_URL', 'http://10.11.1.182:6969')}
    ]
