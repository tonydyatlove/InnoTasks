import click
import logging
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os
from typing import List
import json


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()


@click.command()
@click.option('--rooms-file', default='rooms.json', help='Path to rooms JSON file')
@click.option('--students-file', default='students.json', help='Path to students JSON file')
@click.option('--script-files',
              default=['index1.sql', 'index2.sql', 'query1.sql', 'query2.sql', 'query3.sql', 'query4.sql'],
              help='List of SQL script files')
def logic(rooms_file: str, students_file: str, script_files: List[str]):
    """
       Execute SQL scripts in a PostgreSQL database using data from JSON files and write result data in JSON files.

       Args:
           rooms_file (str): Path to the JSON file containing rooms data.
           students_file (str): Path to the JSON file containing students data.
           script_files (List[str]): List of SQL script files to execute.
       """
    try:
        rooms_data = pd.read_json(rooms_file)
        rooms_data = rooms_data.rename(columns={'id': 'room_id', 'name': 'room_name'})

        students_data = pd.read_json(students_file)
        students_data = students_data.rename(
            columns={'birthday': 'student_birthday', 'id': 'student_id', 'name': 'student_name', 'room': 'room_id',
                     'sex': 'student_sex'})
        students_data['student_birthday'] = pd.to_datetime(students_data['student_birthday'], errors='coerce')

        connection_string = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
        engine = create_engine(connection_string)

        rooms_data.to_sql('rooms', engine, index=False, if_exists='replace')
        students_data.to_sql('students', engine, index=False, if_exists='replace')

        logger.info('Данные успешно загружены в базу данных')

        results = execute_sql_scripts(engine, script_files)

        save_results_to_json(results)

    except Exception as e:
        logger.error(f'Ошибка {e}')
    finally:
        engine.dispose()



def execute_sql_scripts(engine, script_files: List[str]) -> List[dict]:
    """
        Executes SQL scripts in a PostgreSQL database.

        Args:
            engine: SQLAlchemy Engine object representing the database connection.
            script_files (List[str]): List of SQL script files to execute.

        Returns:
            List[dict]: List of dictionaries containing the script file name and the result of each script.
        """
    results = []
    try:
        with open(script_files, 'r') as file:
            query = file.read()

            result = pd.read_sql_query(query, engine)

            result_dict = result.to_dict(orient='records')

            results.append({
            'script_file': script_files,
            'result': result_dict
            })

            logger.info(f'SQL-скрипт успешно выполнен')
    except FileNotFoundError:
        logger.error('Файл не найден')
        return []
    except Exception as e:
        logger.error(f'Ошибка при выполнении SQL-скрипта: {e}')

    return results


def save_results_to_json(results: List[dict]):
    """
       Save the results of SQL scripts to JSON files.

       Args:
           results (List[dict]): List of dictionaries containing the script file name and the result of each script.
       """
    for result in results:
        script_file = result.get('script_file')
        result_data_list = result.get('result')

        json_file_path = f"{script_file}.json"

        with open(json_file_path, 'w') as json_file:
            json.dump(result_data_list, json_file,
                      default=str)

        logger.info(f"Результаты скрипта {script_file} сохранены в файл {json_file_path}")


if __name__ == '__main__':
    logic()
