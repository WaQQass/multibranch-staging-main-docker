import os
import pymysql
from flask import Flask, request, redirect, url_for, render_template_string

app = Flask(__name__)

def get_db_connection():
    return pymysql.connect(
        host=os.getenv('DB_HOST'),  # Use the MySQL container name
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME')
    )

def create_table_if_not_exists():
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS mytable (
            id INT AUTO_INCREMENT PRIMARY KEY,
            data VARCHAR(255) NOT NULL
        )
    """)
    connection.commit()
    cursor.close()
    connection.close()

create_table_if_not_exists()

@app.route('/')
def index():
    return render_template_string(open('index.html').read())

@app.route('/insert', methods=['POST'])
def insert():
    data = request.form['data']
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute("INSERT INTO mytable (data) VALUES (%s)", (data,))
    connection.commit()
    cursor.close()
    connection.close()
    return redirect(url_for('index'))

@app.route('/delete', methods=['POST'])
def delete():
    data_id = request.form['data_id']
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute("DELETE FROM mytable WHERE id=%s", (data_id,))
    connection.commit()
    cursor.close()
    connection.close()
    return redirect(url_for('index'))

@app.route('/show', methods=['GET'])
def show():
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT * FROM mytable")
    result = cursor.fetchall()
    cursor.close()
    connection.close()
    return render_template_string('<h1>Data</h1>' + ''.join(f'<p>{row}</p>' for row in result) + '<a href="/">Back</a>')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
