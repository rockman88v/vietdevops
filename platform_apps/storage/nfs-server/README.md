# Cài đặt NFS server trên AWS EC2
Tham khảo tài liệu hướng dẫn chi tiết ở `https://hail-opinion-177.notion.site/NFS-Storage-installtion-caa274e602a84ad09268460c10eacb99?pvs=4`

## Cài đặt NFS server
Thực hiện cài NFS-server:
```bash
#NFS Server installation
sudo -s
apt update -y
#yum install nfs-utils -y
sudo apt install nfs-kernel-server -y

#Create shared folder
mkdir -p /data/delete
mkdir -p /data/retain

#Change folder
chmod -R 755 /data
#chown -R nfsnobody:nfsnobody /data
chown -R nobody:nogroup /data
 
systemctl restart nfs-server
```

Cấu hình file `/etc/exports` để share quyền cho các node theo format sau mục đích là để cho phép các node trong cùng subnet (`172.31.0.0/16`) có quyền vào 2 thư mục `/data/delete` và `/data/retain`:

***Lưu ý bước này cần check xem các worker node đang ở subnet nào và sử dụng CIDR là gì để update cho đúng***

```bash
/data/retain    172.31.0.0/16(rw,sync,no_root_squash,no_all_squash)
/data/delete    172.31.0.0/16(rw,sync,no_root_squash,no_all_squash)
```

Restart lại NFS server để update cấu hình mới:

```bash
systemctl restart nfs-server
```

Kiểm tra lại xem 2 thư mục trên đã được share bằng lệnh sau:

```bash
root@nfs-server:/home/ubuntu# showmount -e 172.31.25.51
Export list for 172.31.25.51:
/data/delete 172.31.0.0/16
/data/retain 172.31.0.0/16
```

***Lưu ý: Cần mở các Port sau cho các client kết nối được vào NFS server: 111, 2049, 32768-61000***

## Cài đặt NFS Client trên K8S Node

Cần phải cài đặt NFS Client trên tất cả các worker node để khi tạo Pod trên node đó có sử dụng NFS Storage Class thì node đó có thể mount được phân vùng NFS đã được share bởi NFS Server.

Cài NFS Client như sau:

```bash
sudo apt update -y
sudo apt install nfs-common -y
```

Sau đó cũng check lại từ node này đã thấy được các folder được share chưa:

<aside>
💡 Lưu ý `172.31.25.51` là PrivateIP của NFS-server
</aside>

```bash
ubuntu@node-1:~$ sudo showmount -e 172.31.25.51
Export list for 172.31.25.51:
/data/delete 172.31.0.0/16
/data/retain 172.31.0.0/16
```
