## inode学习
### inode 结构中记录的元数据
inode（Index Node）是文件系统中的一个数据结构，每个文件和目录都有一个 inode。它本质上是**文件的身份证 + 地址簿**。

典型 inode 中存储的**元数据**包括：

| 分类 | 内容 | 说明 |
| --- | --- | --- |
| 基本信息 | 文件类型（普通文件、目录、符号链接等） | `ls -l`<br/> 第一个字符 |
| 权限信息 | 读/写/执行权限（rwx） | chmod 管控 |
| 所属关系 | 所有者 UID / 所属组 GID | chown/chgrp 管控 |
| 时间戳 | **ctime**（inode 修改时间）、**mtime**（文件内容修改时间）、**atime**（访问时间） | stat 命令可查看 |
| 大小信息 | 文件大小（字节数） | 对应 stat 中的 `Size` |
| 链接计数 | 硬链接数量 | 0 时文件可被回收 |
| 数据位置 | **block 指针数组** | 指向数据块的物理位置 |




inode 的大小是文件系统创建时确定的（ext2 默认 128 bytes，ext4 常见为 256 bytes；可以配置），更大的 inode 能直接容纳更多元数据或直接存放小文件数据（fast symlink）。

+ `i_mode`  
文件类型（普通文件、目录、符号链接、设备等） + 权限位（rwx、setuid/setgid/sticky）。
+ `i_uid` / `i_gid`  
所属用户 ID / 组 ID。
+ `i_size`  
文件逻辑大小（字节）。现代 ext4 用 64-bit 支持大文件（早期 ext2 为 32-bit）。
+ `i_atime` / `i_mtime` / `i_ctime` / `i_dtime`  
访问时间、内容修改时间、inode 改动时间、删除时间（如果已删除）。
+ `i_links_count`  
硬链接计数（目录项数）；为 0 且没有打开句柄时 inode 可回收。
+ `i_blocks`  
文件占用数据块数 _in 512-byte sectors_（这是传统约定：按 512 字节扇区计数），注意不是按文件系统 blocksize。
+ `i_flags`  
文件标记（如 immutable、noatime 等）。
+ `i_generation`  
文件代数，用于 NFS 等。
+ `i_file_acl` / `i_dir_acl` / xattr 指针  
指向扩展属性或 ACL 的块或 inode 字段（xattr/ACL 可单独存放）。
+ `i_block[15]`（传统索引数组，32-bit 指针常见）  
这是最核心的：通常包含 15 个 32-bit 字（在非-extent 模式下）：
    - `i_block[0..11]`：12 个 **直接块指针**（direct blocks）。
    - `i_block[12]`：**单次间接块指针**（single indirect）— 指向一个块，该块内是数据块地址表。
    - `i_block[13]`：**二次间接**（double indirect）— 指向一个块表，表项指向另一个指针块，再指向数据块。
    - `i_block[14]`：**三次间接**（triple indirect）。

在 ext4 启用 **extents** 时，`i_block` 字段会以 extent header / tree 的形式存放 extent 信息（见下面 extents 部分）。

+ 其他（`i_faddr`、osd 字段等）用于开发者/兼容性或特定扩展。

### inode 中的 block 指针布局
大部分 Unix 文件系统（如 ext2/ext3/ext4）采用**多级索引块指针**的设计，让一个 inode 能指向大文件。

一个典型 inode 可能包含 **15 个指针**：

+ **12 个直接块指针（Direct Blocks）**
    - 每个直接指针直接指向一个数据块（block）
+ **1 个一次间接块指针（Single Indirect）**
    - 指向一个**间接块表**，表中存放的是数据块地址
+ **1 个二次间接块指针（Double Indirect）**
    - 指向一个“间接块表的地址表”
+ **1 个三次间接块指针（Triple Indirect）**
    - 再多套一层

### 直接块 / 间接块 / 多级间接 的寻址机制（含数字示例）
假设典型参数（方便计算与理解；实际系统可不同）：

+ `block_size = 4096 bytes`（4 KiB）
+ 块指针大小 `ptr_size = 4 bytes`（32-bit）
+ 因此，每个间接块能容纳的指针数：
    - `p = block_size / ptr_size = 4096 / 4 = 1024`（逐步算：4096 ÷ 4 = 1024）



### 数据结构（ext4_inode）
The inode table entry is laid out in `struct ext4_inode`.

| Offset | Size | Name | Description |
| :--- | :--- | :--- | :--- |
| 0x0 | __le16 | i_mode | File mode. See the table [<font style="color:rgb(0, 75, 107);">i_mode](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html#i-mode) below. |
| 0x2 | __le16 | i_uid | Lower 16-bits of Owner UID. |
| 0x4 | __le32 | i_size_lo | Lower 32-bits of size in bytes. |
| 0x8 | __le32 | i_atime | Last access time, in seconds since the epoch. However, if the EA_INODE inode flag is set, this inode stores an extended attribute value and this field contains the checksum of the value. |
| 0xC | __le32 | i_ctime | Last inode change time, in seconds since the epoch. However, if the EA_INODE inode flag is set, this inode stores an extended attribute value and this field contains the lower 32 bits of the attribute value’s reference count. |
| 0x10 | __le32 | i_mtime | Last data modification time, in seconds since the epoch. However, if the EA_INODE inode flag is set, this inode stores an extended attribute value and this field contains the number of the inode that owns the extended attribute. |
| 0x14 | __le32 | i_dtime | Deletion Time, in seconds since the epoch. |
| 0x18 | __le16 | i_gid | Lower 16-bits of GID. |
| 0x1A | __le16 | i_links_count | Hard link count. Normally, ext4 does not permit an inode to have more than 65,000 hard links. This applies to files as well as directories, which means that there cannot be more than 64,998 subdirectories in a directory (each subdirectory’s ‘..’ entry counts as a hard link, as does the ‘.’ entry in the directory itself). With the DIR_NLINK feature enabled, ext4 supports more than 64,998 subdirectories by setting this field to 1 to indicate that the number of hard links is not known. |
| 0x1C | __le32 | i_blocks_lo | Lower 32-bits of “block” count. If the huge_file feature flag is not set on the filesystem, the file consumes `i_blocks_lo` 512-byte blocks on disk. If huge_file is set and EXT4_HUGE_FILE_FL is NOT set in `inode.i_flags`, then the file consumes `i_blocks_lo + (i_blocks_hi << 32)` 512-byte blocks on disk. If huge_file is set and EXT4_HUGE_FILE_FL IS set in `inode.i_flags`, then this file consumes (`i_blocks_lo + i_blocks_hi` << 32) filesystem blocks on disk. |
| 0x20 | __le32 | i_flags | Inode flags. See the table [<font style="color:rgb(0, 75, 107);">i_flags](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html#i-flags) below. |
| 0x24 | 4 bytes | i_osd1 | See the table [<font style="color:rgb(0, 75, 107);">i_osd1](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html#i-osd1) for more details. |
| 0x28 | 60 bytes | i_block[EXT4_N_BLOCKS=15] | Block map or extent tree. See the section “The Contents of inode.i_block”. |
| 0x64 | __le32 | i_generation | File version (for NFS). |
| 0x68 | __le32 | i_file_acl_lo | Lower 32-bits of extended attribute block. ACLs are of course one of many possible extended attributes; I think the name of this field is a result of the first use of extended attributes being for ACLs. |
| 0x6C | __le32 | i_size_high / i_dir_acl | Upper 32-bits of file/directory size. In ext2/3 this field was named i_dir_acl, though it was usually set to zero and never used. |
| 0x70 | __le32 | i_obso_faddr | (Obsolete) fragment address. |
| 0x74 | 12 bytes | i_osd2 | See the table [<font style="color:rgb(0, 75, 107);">i_osd2](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html#i-osd2) for more details. |
| 0x80 | __le16 | i_extra_isize | Size of this inode - 128. Alternately, the size of the extended inode fields beyond the original ext2 inode, including this field. |
| 0x82 | __le16 | i_checksum_hi | Upper 16-bits of the inode checksum. |
| 0x84 | __le32 | i_ctime_extra | Extra change time bits. This provides sub-second precision. See Inode Timestamps section. |
| 0x88 | __le32 | i_mtime_extra | Extra modification time bits. This provides sub-second precision. |
| 0x8C | __le32 | i_atime_extra | Extra access time bits. This provides sub-second precision. |
| 0x90 | __le32 | i_crtime | File creation time, in seconds since the epoch. |
| 0x94 | __le32 | i_crtime_extra | Extra file creation time bits. This provides sub-second precision. |
| 0x98 | __le32 | i_version_hi | Upper 32-bits for version number. |
| 0x9C | __le32 | i_projid | Project ID. |




The `i_mode` value is a combination of the following flags:

| Value | Description |
| :--- | :--- |
| 0x1 | S_IXOTH (Others may execute) |
| 0x2 | S_IWOTH (Others may write) |
| 0x4 | S_IROTH (Others may read) |
| 0x8 | S_IXGRP (Group members may execute) |
| 0x10 | S_IWGRP (Group members may write) |
| 0x20 | S_IRGRP (Group members may read) |
| 0x40 | S_IXUSR (Owner may execute) |
| 0x80 | S_IWUSR (Owner may write) |
| 0x100 | S_IRUSR (Owner may read) |
| 0x200 | S_ISVTX (Sticky bit) |
| 0x400 | S_ISGID (Set GID) |
| 0x800 | S_ISUID (Set UID) |
| | These are mutually-exclusive file types: |
| 0x1000 | S_IFIFO (FIFO) |
| 0x2000 | S_IFCHR (Character device) |
| 0x4000 | S_IFDIR (Directory) |
| 0x6000 | S_IFBLK (Block device) |
| 0x8000 | S_IFREG (Regular file) |
| 0xA000 | S_IFLNK (Symbolic link) |
| 0xC000 | S_IFSOCK (Socket) |




### 扇区（Sector）
扇区（Sector）是最小可寻址的物理存储单位，磁盘的读写都是以扇区为单位，不能只写一个字节，必须读出整个扇区，修改后再写回。

+ 在传统硬盘（HDD）上，扇区大小几乎总是 **512字节**（512B）。
+ 现代硬盘和 SSD 有 **4K 扇区**（Advanced Format），但为了兼容，逻辑上可能仍呈现为 512B。

文件系统不会直接管理每个扇区，而是将多个扇区组成一个 **块（Block）**：

+ **块大小**：常见 1K、2K、4K（一个块 = 若干个扇区）。假设块大小 = 4K，一个块可能对应 **8 个 512B 扇区**。
+ inode 和数据块都存储在这些块中
+ 文件系统会在磁盘上预先划分好 **超级块（superblock）、inode表、数据块区域** 等

### **目录项（Directory Entry）**
##### Linear (Classic) Directories
| Offset | Size | Name | Description |
| :--- | :--- | :--- | :--- |
| 0x0 | __le32 | inode | Number of the inode that this directory entry points to. |
| 0x4 | __le16 | rec_len | Length of this directory entry. Must be a multiple of 4. |
| 0x6 | __le16 | name_len | Length of the file name. |
| 0x8 | char | name[EXT4_NAME_LEN] | File name. |


##### Hash Tree Directories
A linear array of directory entries isn’t great for performance, so a new feature was added to ext3 to provide a faster (but peculiar) balanced tree keyed off a hash of the directory entry name. 

### 文件操作
##### 查询（路径解析）
`open("/home/user/file.txt")` 时：

1. VFS（虚拟文件系统）读取 `/` 根目录的目录文件
2. 找到 `"home"` 的目录项，拿到 inode 号
3. 打开 `"home"` 目录文件，找到 `"user"` 的 inode 号
4. 打开 `"user"` 目录文件，找到 `"file.txt"` 的 inode 号
5. 用这个 inode 找到数据块和数据扇区

##### 新建
```java
int fd = open("test.txt", O_CREAT | O_WRONLY, 0644);
```

+ **VFS**（虚拟文件系统）负责统一处理，不直接操作磁盘
+ 如果文件不存在，VFS 调用底层文件系统（如 ext4）的 `create()` 方法

文件系统内部步骤：

1. 路径解析
    1. 确认 `test.txt` 不存在
    2. 找到当前目录所在的 **inode** 和数据块位置
2. 分配 inode
    1. 从 inode bitmap 中找到一个空闲的 inode（位图上为 0 的位置）将它标记为已用（置 1）
    2. 在 inode table 中写入该 inode 的元数据
3. 更新目录文件（增加目录项）
    1. 在父目录的 **数据块** 中添加一条 **目录项（Directory Entry）**
    2. 如果当前数据块没有足够空间，可能会分配一个新的数据块给目录文件
4. 分配数据块（如果写入内容）
    1. 如果只是新建空文件，这一步可以不分配
    2. 写入内容时：
        1. 从 block bitmap 找空闲块（位 0）
        2. 标记为已用（置 1）
        3. 在 inode 的 direct block 指针中记录该块号
        4. 如果 direct block 用完，用 single indirect / double indirect 机制
5. 写回磁盘（缓存 → 磁盘）
    1. Linux 使用 **页缓存（Page Cache）** 和 **缓冲区（Buffer Cache）**
    2. 实际写盘时可能延迟（`write-back` 策略）
    3. `fsync()` 或文件关闭时会强制同步：
        * inode table 更新
        * block bitmap 更新
        * inode bitmap 更新
        * 目录文件数据块更新
        * 文件数据块更新

```markdown
用户进程
    │ open("test.txt", O_CREAT)
    ▼
VFS
    │ 检查路径，调用 ext4_create()
    ▼
ext4 文件系统
    │ 分配 inode（inode bitmap → inode table）
    │ 更新目录文件（添加目录项）
    │ （如写入内容）分配数据块（block bitmap → data block）
    ▼
页缓存/缓冲区
    │ 缓存修改
    ▼
磁盘
    │ inode table
    │ 目录文件数据块
    │ block bitmap / inode bitmap

```

##### 删除
当文件删除时，标记相应的inode bitmap和 block bitmap空闲。因此有一定概率可以恢复数据（没有新数据写入这些块时）

### 磁盘格式化
```markdown
sudo mkfs.ext4 -b 4096 -i 16384 -m 1 \
  -L DATA -U random \
  -O metadata_csum,64bit \
  -E lazy_itable_init=1,lazy_journal_init=1 \
  /dev/sdb1
```

常用关键参数（括号内是 `mke2fs` 等价项）：

+ **块大小**：`-b 4096`（`-b`）→ 典型 4KiB
+ **每 inode 对应的字节数**：`-i 16384`（或用 `-N` 指定 inode 总数）
+ **预留给 root 的比例**：`-m 1`（默认 5%，数据盘常改小）
+ **卷标/UUID**：`-L DATA`、`-U random|time|<uuid>`
+ **特性开关**（superblock 标记）：`-O <feature,feature>`
    - 常见：`extents,dir_index,uninit_bg,has_journal,metadata_csum,64bit,sparse_super2` 等
+ **RAID/SSD 优化**：`-E stride=<N>,stripe-width=<M>,nodiscard`
+ **日志（journal）**：`-J size=<MB>` 或 `-O ^has_journal` 关闭（不建议）
+ **懒初始化**：`-E lazy_itable_init=1,lazy_journal_init=1`（默认开启，mkfs 很快；首次挂载后台补零）



**步骤总览：**

1. **读取设备几何参数**，解析命令行/配置（`/etc/mke2fs.conf`），确定：
    - block size、blocks per group、inodes per group、组数量
    - 启用哪些特性（compat/ro_compat/incompat）
    - 日志（internal/external）大小与位置
2. **写入 Superblock（主副本）与 Group Descriptor Table**
    - 主 superblock 位于文件系统开头处（偏移 1024B 起）；
    - 按特性（如 `sparse_super2`）在若干组写 **备份 superblock + 组描述符**。
3. **为每个 Block Group 布局并初始化：**
    - **Block Bitmap**：标记“哪些块正被元数据占用”置 1（比如 superblock、GDT、bitmap 自身、inode table、lost+found 等），其余置 0。
    - **Inode Bitmap**：初始全 0，但会把系统已占用的 inode 置 1（如根目录、日志等）。
    - **Inode Table**：按照 inode size 预留连续区域。
        * 若 **懒初始化**开（`lazy_itable_init=1`），mkfs 只做最小写入（记录为未初始化），首次挂载由内核在后台清零；
        * 若关闭懒初始化，则 mkfs 直接把整张 inode table 清零，会更慢。
4. **创建关键目录与文件：**
    - **根目录 **`**/**`**（inode #2）**：分配 inode + 一个数据块，目录里至少有 `.` 和 `..` 项；
    - `**lost+found/**`：预创建并扩展一些块，便于将来 fsck 恢复孤儿文件；
    - **Journal（JBD2）**：若启用 `has_journal`（默认 ext4 会启），创建日志 inode，分配连续块并写入 journal superblock、日志头结构。
5. **写入特性标志、统计与元数据校验**
    - 在 superblock / GDT 中记录：总块/总 inode、每组空闲计数、启用特性（例如 `extents, metadata_csum, 64bit` 等）；
    - 计算并写入元数据校验（`metadata_csum` 打开时）。
6. **完成：输出布局摘要**（设备大小、块大小、inode 大小/数量、journal 大小、特性列表、备用 superblocks 等）。



```markdown
Block Group N
 ├─ Superblock（只在少数组有备份）
 ├─ Group Descriptor Table（部分组有备份）
 ├─ Block Bitmap
 ├─ Inode Bitmap
 ├─ Inode Table
 └─ Data Blocks  ← 普通文件/目录/日志数据主体都在这里
```

参考资料：

[https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html)

[https://elixir.bootlin.com/linux/v6.2-rc1/source/include/linux/fs.h#L593](https://elixir.bootlin.com/linux/v6.2-rc1/source/include/linux/fs.h#L593)

[https://litux.nl/mirror/kerneldevelopment/0672327201/ch12lev1sec6.html](https://litux.nl/mirror/kerneldevelopment/0672327201/ch12lev1sec6.html)

