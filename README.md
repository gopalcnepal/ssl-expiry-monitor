<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![project_license][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<div align="center">
  <h3 align="center">SSL Certificate Expiry Monitor</h3>

  <p align="center">
    A web application to track and monitor SSL certificate expiration dates for multiple domains
    <br />
    <br />
    ·
    <a href="https://github.com/gopalcnepal/ssl-expiry-monitor/issues">Report Bug</a>
    ·
    <a href="https://github.com/gopalcnepal/ssl-expiry-monitor/issues">Request Feature</a>
  </p>
</div>

## About The Project

![SSL Certificate Expiry Monitor](./screenshot/screenshot.png)

SSL Certificate Expiry Monitor is a Flask-based web application that helps you keep track of SSL certificates for multiple domains. It provides a simple dashboard to monitor expiration dates and sends alerts when certificates are approaching expiration.

Key features:
* Add and manage multiple domains
* Automatic SSL certificate expiry date checking
* Visual alerts for certificates expiring soon
* Add notes for each domain
* Easy-to-use dashboard interface

### Built With

* ![Flask][Flask]
* ![Bootstrap][Bootstrap]
* ![SQLAlchemy][SQLAlchemy]
* ![SQLite][SQLite]

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

* Python 3.8 or higher
* pip (Python package manager)

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/gopalcnepal/ssl-expiry-monitor.git
   ```
2. Create and activate a virtual environment
   ```sh
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install required packages
   ```sh
   pip install -r requirements.txt
   ```
4. Run the application
   ```sh
   python -m flask run
   ```

## Usage

1. Access the application at `http://localhost:5000`
2. Add domains using the form on the left side
3. View certificate information in the main table
4. Use the refresh button to update certificate information
5. Edit or delete entries as needed

The dashboard will show visual alerts:
* 🟡 Yellow warning for certificates expiring within 30 days
* 🔴 Red warning for certificates expiring within 7 days

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Project Link: [https://github.com/gopalcnepal/ssl-expiry-monitor](https://github.com/gopalcnepal/ssl-expiry-monitor)

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/gopalcnepal/ssl-expiry-monitor.svg?style=for-the-badge
[contributors-url]: https://github.com/gopalcnepal/ssl-expiry-monitor/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/gopalcnepal/ssl-expiry-monitor.svg?style=for-the-badge
[forks-url]: https://github.com/gopalcnepal/ssl-expiry-monitor/network/members
[stars-shield]: https://img.shields.io/github/stars/gopalcnepal/ssl-expiry-monitor.svg?style=for-the-badge
[stars-url]: https://github.com/gopalcnepal/ssl-expiry-monitor/stargazers
[issues-shield]: https://img.shields.io/github/issues/gopalcnepal/ssl-expiry-monitor.svg?style=for-the-badge
[issues-url]: https://github.com/gopalcnepal/ssl-expiry-monitor/issues
[license-shield]: https://img.shields.io/github/license/gopalcnepal/ssl-expiry-monitor.svg?style=for-the-badge
[license-url]: https://github.com/gopalcnepal/ssl-expiry-monitor/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/gopalcnepal
[Flask]: https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white
[Bootstrap]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[SQLAlchemy]: https://img.shields.io/badge/SQLAlchemy-FF0000?style=for-the-badge&logo=python&logoColor=white
[SQLite]: https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white
