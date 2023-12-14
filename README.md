
# Hotel Reservations - ADASTRA

<hr>

### Contributors

**Alexander Parpulansky - Service/Payment**

**Nikolay Kalchev - Room/Client**

**Pavel Ivanov - Reservation/Review**

**Alexander Stoyanov - Roles**

### Content

**tables.sql - Tables DDL**

**index.sql - Table Indices**

**roles.sql - Roles and users**

**trigger.sql - Triggers for insertions and updates**

**insert.sql - Table mock data**

**query.sql - 4 Queries**

### How to Run

* Clone the repository

``` Bash
git clone https://github.com/aparpEdu/hotel-db.git
```

* Run DDL scripts
``` Bash
psql -U postgres -d your_database -f run.sql
```
* Insert Data
``` Bash
psql -U postgres -d your_database -f insert.sql
```
* Add Roles
``` Bash
psql -U postgres -d your_database -f roles.sql
```
