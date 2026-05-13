# Tự động tạo VM và cài cụm Multi-master Kubernetes
Tạo VM tự động bằng Vagrant + VMWare workstation: Sử dụng vagrant file mẫu ở đây

Cài đặt cụm Multi-master kubernetes cluster tự động bằng ansible (bootstrap bằng kubeadm)


# Chuẩn bị 
Một số công cụ cần chuẩn bị:
- Cài đặt VMWare workstation pro
- Cài Vagrant (trên window) + addon/utility
- Cài WSL + Ubuntu (trên window) -> Để chạy ansible

## Cài Vagrant trên window
Dùng powershell (quyền Admin) để chạy lệnh:
```
#Cài choco
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```
Cài `vagrant`:
```
choco install vagrant
vagrant --version

```
## Cài VMware Utility cho Vagrant
Cài plugin:
```
vagrant plugin install vagrant-vmware-desktop
```
Sau đó cài `Vagrant VMware Utility` (theo tài liệu trên web): https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility


Cài thêm plugins `vagrant-disksize`:
```
vagrant plugin install vagrant-disksize
```

## Cài WSL/Ubuntu trên window
Vào Microsoft store để cài WSL và ubuntu

Cần bật một số tính năng của window để nó có thể chạy dc
```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

wsl --update

wsl --install -d ubuntu
```

Sau đó reboot và bật lại ubuntu lên để finish setup:
```
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username: sysadmin
New password:
Retype new password:
passwd: password updated successfully
Installation successful!
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

sysadmin@Viet-PC:~$
```

Mở ubuntu (trên window) và cài ansible:
```
sudo apt update

sudo apt install -y \
  ansible \
  sshpass

ansible --version  
```

# Tạo VM bằng Vagrant
 **Note:**  
- Cần bật VMWare workstation trước khi chạy lệnh Vagrant
Sửa nội dung file `Vagrantfile` để tùy biến VM bạn muốn tạo gồm có IP, CPU/Mem và disk.
- Nếu đổi tên VM thì cần update lại tương ứng ở file `inventory.ini` để chạy ansible sau này
- Lưu ý là tạo đúng 3 master, và N worker
- Mặc định VMNet1 của VMWare workstation sẽ là host-only network
- User/pass SSH mặc định cho Vm là vagrant/vagrant. Bạn có thể tùy biến việc tạo user bằng cách sửa script bootstrap.sh 

## Tạo VM
Download ubuntu box trước:
```
vagrant box add bento/ubuntu-24.04
```

Mở powershell vào đúng thư mục chứa vagrant file chạy lệnh:
```
vagrant up --provider=vmware_desktop
```
Chờ chút để vagrant tạo các VM

Một số lệnh quản lý VM bằng vagrant (đứng từ thư mục chứa Vagrantfile):
```
#Start VM
vagrant up

#Tạo riêng 1 VM
vagrant up worker1

#Stop VM
vagrant halt

#Restart VM
vagrant reload

#Re-run provision
vagrant provision

#SSH
vagrant ssh master

#Xóa toàn bộ
vagrant destroy -f
```

Trong ví dụ này sẽ tạo 5 VM:
```
192.168.10.61 master1
192.168.10.62 master2
192.168.10.63 master3
192.168.10.64 worker1
192.168.10.65 worker2
```
Trong đó 3 master sẽ được cấu hình VIP là `192.168.10.60` để làm IP ảo đóng vai trò LB của 3 master

# Cài đặt K8S
Sửa file `ansible\inventory.ini` và `ansible\group_vars\all.yml` với thông tin IP/Hostname đúng với những gì bạn đã tạo ở bước trước

Nếu bạn tạo ít hay nhiều worker hơn thì sửa file `ansible\inventory.ini` tương ứng. 

Sau đó mở ubuntu, vào đúng thư mục chứa ansible này và chạy lệnh:
```
export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -i inventory.ini site.yml
```

Kết quả sau khi chạy xong sẽ như sau:
```
TASK [worker : Join worker node] ****************************************************************************************************
changed: [worker2]
changed: [worker1]

TASK [worker : Wait for node Ready] *************************************************************************************************
changed: [worker1 -> master1(192.168.100.61)]
changed: [worker2 -> master1(192.168.100.61)]

PLAY RECAP **************************************************************************************************************************
master1                    : ok=67   changed=43   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
master2                    : ok=55   changed=34   unreachable=0    failed=0    skipped=20   rescued=0    ignored=0
master3                    : ok=53   changed=32   unreachable=0    failed=0    skipped=20   rescued=0    ignored=0
worker1                    : ok=45   changed=25   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
worker2                    : ok=44   changed=25   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Bạn SSH vào master node và check:
```
vagrant@master1:~$ kgno
NAME      STATUS   ROLES           AGE    VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
master1   Ready    control-plane   134m   v1.34.8   192.168.100.61   <none>        Ubuntu 24.04.3 LTS   6.8.0-86-generic   containerd://2.2.3
master2   Ready    control-plane   129m   v1.34.8   192.168.100.62   <none>        Ubuntu 24.04.3 LTS   6.8.0-86-generic   containerd://2.2.3
master3   Ready    control-plane   128m   v1.34.8   192.168.100.63   <none>        Ubuntu 24.04.3 LTS   6.8.0-86-generic   containerd://2.2.3
worker1   Ready    <none>          127m   v1.34.8   192.168.100.64   <none>        Ubuntu 24.04.3 LTS   6.8.0-86-generic   containerd://2.2.3
worker2   Ready    <none>          127m   v1.34.8   192.168.100.65   <none>        Ubuntu 24.04.3 LTS   6.8.0-86-generic   containerd://2.2.3
```

Như vậy là việc cài đặt đã hoàn thành. Chúc các bạn thành công.