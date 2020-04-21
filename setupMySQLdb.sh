docker run --name steampress-test-mysql -e MYSQL_USER=steampress -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=steampress-test -p 3307:3306 -d mysql/mysql-server:5.7
