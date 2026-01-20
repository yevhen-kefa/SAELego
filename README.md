# 🧱 img2brick

> **High-performance web application that transforms personal photos into optimized LEGO® brick mosaics using a hybrid PHP/Java/C architecture.**

![Project Status](https://img.shields.io/badge/Status-Completed-success)
![Context](https://img.shields.io/badge/Context-Academic_Project-blue)
![Tech Stack](https://img.shields.io/badge/Stack-PHP_|_Java_|_C_|_MySQL-orange)

## 📖 Overview

**img2brick** is a full-stack web application designed to bridge the gap between digital images and physical brick art. Unlike simple pixel art filters, this project utilizes a custom **multi-language pipeline** to process images, manage inventory, and optimize brick placement for cost and visual fidelity.

Built as part of the BUT2 Computer Science curriculum, this project demonstrates complex system integration, algorithmic optimization, and secure web development practices.

### 🌟 Key Features

* **Interactive Web Interface:** Drag-and-drop upload, image cropping (Cropper.js), and real-time visualization.
* **Algorithmic Optimization (C):** A dedicated solver written in C to handle the "Paving Problem" — finding the optimal arrangement of brick sizes (1x1 to 2x4) to minimize cost.
* **Image Processing (Java):** High-quality resizing and color quantization matching real-world LEGO® palettes.
* **E-Commerce Simulation:** Full order lifecycle management including user registration, 2FA (Email), PDF invoice generation, and mock payments (Proof of Work).
* **Custom MVC Architecture:** The PHP frontend is built on a lightweight, custom-written MVC framework without reliance on heavy external libraries.

---

## 🏗 Technical Architecture

The system follows a modular architecture where each language is used for its specific strengths:

| Layer | Language | Responsibility |
| :--- | :--- | :--- |
| **Frontend & Core** | **PHP 7.4+** | Web server, Custom MVC, User Session Management, PDF Generation. |
| **Orchestration** | **Java 11+** | Middleware logic, Image processing, Database synchronization, calling the C solver. |
| **Solver Engine** | **C** | High-performance computational logic for paving optimization. |
| **Data Persistence** | **MySQL** | Storage for Users, Orders, Brick Inventory, and Color Mappings. |

### Data Flow Pipeline
1.  **User** uploads an image via the **PHP** interface.
2.  **PHP** passes the file path to the **Java** module.
3.  **Java** processes the image (resizing/quantization) and generates a pixel matrix.
4.  **Java** executes the **C binary**, passing the matrix and brick inventory.
5.  **C** calculates the optimal layout and returns a solution file (`outV3.txt`).
6.  **PHP** parses the result to display the mosaic and generate a quote.

---

## 📂 Project Structure

SAELEGO/
├── C/                      # Optimization Algorithm
│   └── pavage.c            # Core C solver logic
├── PHP/                    # Web Application (Custom MVC)
│   ├── public/             # Entry point (index.php)
│   ├── src/                # Controllers, Entities, Services
│   ├── config/             # Configuration (DB, Mail)
│   └── templates/          # HTML Views
├── sae_java_group/         # Backend Middleware
│   ├── src/                # Java source code
│   ├── colors.csv          # Color palette reference
│   └── bricks.txt          # Brick shapes reference
└── SQL/                    # Database Scripts
    └── dmp_lego_app.sql    # Initial database schema and data



# ⚙️ Setup & Installation

Follow the steps below to deploy the project locally.

## Prerequisites
Make sure the following tools and services are installed on your system:
-   **Web Server:** Apache or Nginx (with PHP 7.4+ extensions enabled)
-   **Database:** MySQL 5.7 or 8.0
-   **Compilers:**
    -   GCC (for C)
    -   JDK 11+ (for Java)
-   **Package Manager:** Composer (for PHP dependencies)


## 1. Database Configuration

Create the database and import the initial schema:
``` bash
mysql -u root -p -e "CREATE DATABASE lego_app;"
mysql -u root -p lego_app < SQL/dmp_lego_app.sql
```

## 2. Compile the Solver (C)

The C source code must be compiled into an executable named `pavage` and
placed where the Java application can access it.
``` bash
cd C/
gcc pavage.c -o pavage
# Copy the executable to the Java project root
cp pavage ../sae_java_group/
```

## 3. Build the Backend (Java)

Compile the Java classes using an IDE (IntelliJ IDEA, Eclipse) or the
command line.
``` bash
cd ../sae_java_group
# Compile and place output into the 'target' directory
# We use -sourcepath to ensure dependencies (like DatabaseManager) are found
javac -sourcepath src/main/java -d target src/main/java/fr/univ_eiffel/Main.java
```

> **Note:**\
> Ensure that `colors.csv` and `bricks.txt` exist in the
> `sae_java_group/` directory.


## 4. Configure the Web App (PHP)

### Install Dependencies

``` bash
cd ../PHP
composer install
```

### Environment Configuration

Rename the example configuration files and update them with your own
credentials:
``` bash
cp config_example/database_example.php config/database.php
cp config_example/mail_example.php config/mail.php
```

Edit `config/database.php` to match your MySQL username and password.



## 🚀 Usage

1.  Start your local web server pointing to `PHP/public`.
    Example:
    ``` bash
    php -S localhost:8000 -t PHP/public
    ```
2.  Open your browser and navigate to:
        http://localhost:8000
3.  Register a new account\
    (use a valid email format for the mock 2FA system).
4.  Upload an image from the dashboard.
5.  Crop the area you want to transform.
6.  Click **Generate** to trigger the Java/C processing pipeline.
7.  View the generated result, check the quote, and proceed to checkout.


## 🔮 Roadmap

 * [ ] Dockerization: Create a docker-compose.yml to orchestrate PHP, Java, and MySQL containers automatically.

 * [ ] API Integration: Refactor the file-based communication between PHP and Java to a RESTful API.

 * [ ] Performance: Optimize the C algorithm for high-resolution paving (>128x128 studs).


## 👥 Authors

Project developed by a team of 4 students from IUT Marne-la-Vallée (Université Gustave Eiffel).