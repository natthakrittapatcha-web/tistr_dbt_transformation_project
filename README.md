# TISTR Data Warehouse & Modern Data Pipeline 🚀

โปรเจกต์นี้เป็นการพัฒนาระบบคลังข้อมูล (Data Warehouse) และท่อส่งข้อมูล (Data Pipeline) ที่ปลอดภัยตามมาตรฐาน PDPA สำหรับสถาบันวิจัยวิทยาศาสตร์และเทคโนโลยีแห่งประเทศไทย (วว.) โดยครอบคลุมตั้งแต่การสกัดข้อมูล (Extract) การเข้ารหัสข้อมูลส่วนบุคคลภายในองค์กร (Masking/Encryption) จนถึงการทำ Data Modeling ด้วย dbt บนระบบ Cloud

---

## 📁 โครงสร้างโฟลเดอร์ของ dbt Models

ในการทำ Data Modeling ได้มีการจัดกลุ่มข้อมูลออกเป็น 3 Layer ตามหลัก dbt Best Practices ดังนี้:

```text
tistr_project/                 # โฟลเดอร์หลักของโปรเจกต์
├── dbt_project.yml            # ไฟล์คอนฟิกของ dbt
├── models/                    # โฟลเดอร์ระบบ dbt Models (โค้ด SQL เท่านั้น)
│   ├── staging/
│   └── marts/
│
├── mock_s3_bucket/            # 📁 โฟลเดอร์ที่จำลองมาจาก AWS S3 
   ├── raw/                   # ชั้นข้อมูลดิบ 
   │   ├── sap/
   │   │   └── master_band.csv
   │   └── hris/
   │       └── employee_raw.csv
   └── gold_model/           # ชั้นข้อมูลที่ dbt ประมวลผลเสร็จแล้ว (ตัวอย่างผลลัพธ์)


models/
├── staging/                # (ชั้นพักข้อมูลดิบที่ Clean และแปลงชื่อคอลัมน์แล้ว)
├── intermediate/           # (ชั้น Integration Layer สำหรับ Join และปรับมาตรฐานข้อมูล)
└── marts/                  # (ชั้น Gold สำหรับนำไปใช้ทำ Report หรือเชื่อมต่อ CKAN)
    └── core/
        └── dim_employee.sql
```
# 🛠️ คู่มือการติดตั้งและการใช้งาน dbt (dbt Installation & Usage Guide)

คู่มือนี้จัดทำขึ้นเพื่ออธิบายขั้นตอนการตั้งค่าระบบ Environment การติดตั้ง dbt และคำสั่งที่จำเป็นในการรันโมเดลข้อมูลสำหรับโปรเจกต์ **TISTR Data Warehouse** 

---

## 📋 1. การเตรียมความพร้อมก่อนติดตั้ง (Pre-requisites)

ก่อนเริ่มดำเนินการ โปรดตรวจสอบให้แน่ใจว่าเครื่องคอมพิวเตอร์หรือ Server ของคุณมีคุณสมบัติดังนี้:
* ติดตั้ง **Python 3.10** หรือเวอร์ชันที่สูงกว่าเรียบร้อยแล้ว
* มีสิทธิ์การเข้าถึงคลังข้อมูลปลายทาง หรือระบบ Cloud (AWS S3 / Athena)
* มีเครื่องมือ Command Line (เช่น Terminal, Command Prompt หรือ PowerShell)

---

## 🚀 2. ขั้นตอนการติดตั้ง (Installation Steps)

ให้เปิด Terminal ในโฟลเดอร์หลักของโปรเจกต์ (`tistr_project`) แล้วรันคำสั่งตามลำดับดังต่อไปนี้:

### สเต็ป 2.1: สร้าง Virtual Environment
เพื่อป้องกันไม่ให้เวอร์ชันของ Library ของโปรเจกต์นี้ไปปนหรือตีกับโปรแกรมอื่นในเครื่อง ให้สร้างโฟลเดอร์จำลองสภาพแวดล้อมเฉพาะขึ้นมา:
```bash
# สร้าง venv ชื่อ dbt-env ไว้ในโปรเจกต์
python -m venv dbt-env
```

### สเต็ป 2.2: เปิดใช้งาน Virtual Environment (Activate)

เลือกใช้คำสั่งตามระบบปฏิบัติการและเครื่องมือที่คุณใช้งานอยู่:

#### สำหรับ Windows (ผ่าน Command Prompt)

```cmd
dbt-env\Scripts\activate
```

#### สำหรับ Windows (ผ่าน PowerShell)

```powershell
.\dbt-env\Scripts\activate
```

#### สำหรับ Mac / Linux / Git Bash

```bash
source dbt-env/bin/activate
```


> 💡 **ข้อสังเกต:** เมื่อเปิดใช้งานสำเร็จ จะมีตัวอักษร `(dbt-env)` แสดงขึ้นมาที่ด้านหน้าสุดของบรรทัดพิมพ์คำสั่งใน Terminal

---

#### สเต็ป 2.3: ติดตั้ง dbt และ Adapter สำหรับ AWS Athena

พิมพ์คำสั่งด้านล่างนี้เพื่อติดตั้ง dbt Core พร้อมกับปลั๊กอินที่ใช้เชื่อมต่อกับ AWS Athena:

```bash
pip install dbt-core dbt-athena-community
```

> หรือหากมีไฟล์ `requirements.txt` อยู่ในโปรเจกต์ สามารถใช้คำสั่งด้านล่างแทนได้:

```bash
pip install -r requirements.txt
```

---

## ⚙️ 3. การตั้งค่าการเชื่อมต่อฐานข้อมูล (Configuration)

dbt จะใช้ไฟล์โครงสร้างที่ชื่อว่า `profiles.yml` ในการเก็บข้อมูลสิทธิ์และเส้นทางการเชื่อมต่อฐานข้อมูล

> ⚠️ **ข้อควรระวังสูงสุด:** ปกติไฟล์นี้จะถูกเก็บไว้ที่โฟลเดอร์ของผู้ใช้ภายนอกโปรเจกต์ (ตำแหน่ง `~/.dbt/` ในเครื่อง) เพื่อความปลอดภัย **ห้ามนำไฟล์ที่มีรหัสผ่านจริง Push ขึ้น GitHub เด็ดขาด** (ระบุไว้ใน `.gitignore` เรียบร้อยแล้ว)

### ตัวอย่างโครงสร้างไฟล์ `profiles.yml` สำหรับเชื่อมต่อ AWS Athena

```yaml
tistr_profile:
  target: dev
  outputs:
    dev:
      type: athena
      s3_staging_dir: s3://your-s3-bucket-athena-results/
      region_name: ap-southeast-1 #ควรปรับให้ตรงกับภูมิภาคของตัวเอง
      database: tistr_data_warehouse
      schema: dev_marts
      workgroup: primary
```

---

## 💻 4. คำสั่งการใช้งาน dbt ที่สำคัญ (Core dbt Commands)

เมื่อตั้งค่าทุกอย่างเสร็จสิ้นแล้ว คุณสามารถควบคุมระบบ Pipeline ผ่านคำสั่งเหล่านี้ใน Terminal (ขณะที่เปิดใช้งาน `dbt-env` อยู่)

---

### 🔍 4.1 ตรวจสอบการเชื่อมต่อ

ใช้สำหรับเช็คว่าการตั้งค่าในโปรเจกต์และไฟล์ `profiles.yml` สามารถเชื่อมต่อกับ AWS Athena ได้ถูกต้องหรือไม่

```bash
dbt debug
```

---

### 📦 4.2 ติดตั้ง Package เสริม

ดาวน์โหลดปลั๊กอินหรือโมดูลเสริมที่โปรเจกต์ dbt จำเป็นต้องใช้ร่วมกัน (รันคำสั่งนี้เฉพาะการใช้งานครั้งแรก)

```bash
dbt deps
```

---

### 🏗️ 4.3 ประมวลผลข้อมูลและสร้างตารางจริง (คำสั่งหลัก)

สั่งรันโค้ด SQL ทุกชั้นข้อมูลเพื่อแปลงและย้ายข้อมูลจากตารางดิบขึ้นไปเป็นตารางสำเร็จรูปในคลังข้อมูล
(Staging → Intermediate → Marts)

```bash
dbt run
```

#### ตัวอย่างการรันเฉพาะบางโมเดล

```bash
dbt run --select stg_customer.sql
```

> รันเฉพาะโมเดล staging ของ customer

```bash
dbt run --select dim_employee
```

> รันเฉพาะโมเดลตารางพนักงาน

---

### 🧪 4.4 ทดสอบความถูกต้องข้อมูล (Data Quality Test)

สั่งตรวจสอบความถูกต้องของข้อมูลตามเงื่อนไข (Constraints) ที่เขียนกำกับไว้ในไฟล์ `.yml`

ตัวอย่างเช่น:

* ตรวจสอบคอลัมน์ห้ามเป็นค่าว่าง (`not_null`)
* ตรวจสอบข้อมูลห้ามซ้ำ (`unique`)

```bash
dbt test
```

---

### 📖 4.5 สร้างเอกสารและสายสัมพันธ์ข้อมูล (Data Lineage)

สั่งให้ dbt สร้างหน้าเว็บภายในเครื่องเพื่อเปิดดู:

* Data Dictionary
* รายละเอียดคอลัมน์
* แผนผังการไหลของข้อมูล (Lineage Graph)

```bash
dbt docs generate
dbt docs serve
```
เมื่อต้องการเลิกใช้งาน กดปุ่ม `Ctrl + C` หรือ พิมพ์คำสั่ง
```bash
dbt docs generate && dbt docs serve
```
---

## 💡 5. ข้อแนะนำและข้อควรระวังในการพัฒนา

### 1. ลืมเปิด Environment

ก่อนพิมพ์คำสั่ง `dbt` ทุกครั้ง อย่าลืมเช็คว่าได้รันคำสั่งเปิดใช้งาน `dbt-env` ในสเต็ป 2.2 แล้วหรือยัง

หากยังไม่ได้เปิดใช้งาน ระบบจะฟ้องว่า:

```bash
dbt: command not found
```

หรือใน Windows อาจขึ้นว่า:

```powershell
'dbt' is not recognized as an internal or external command
```

---

### 2. การจัดการไฟล์ข้อมูล

ไฟล์ข้อมูลดิบที่เป็นข้อมูลจำลอง (Mock Data สำหรับทดสอบ) ได้ถูกแยกไว้ที่โฟลเดอร์:

```text
mock_s3_bucket/
```

> ⚠️ **ข้อควรระวัง:**
> ห้ามนำไฟล์ข้อมูลขนาดใหญ่ หรือไฟล์ `.csv` ไปวางไว้ภายในโฟลเดอร์ `models/**` เพราะจะทำให้ dbt ทำงานผิดพลาดขณะ Compile SQL

