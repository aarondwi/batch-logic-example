import psycopg2

import threading
from time import time
from queue import Queue
import statistics
from random import shuffle

NUM_OF_WORK = 1_500_000
NUM_OF_WORKER = 4
BATCH_SIZE = 1000
time_list = []

query = (
  "CALL sp_batch_flash_sale(1,"
  f"{','.join(['ARRAY[]::INT[]'] * 4)},"
  f"VARIADIC ARRAY[{','.join(['%s'] * BATCH_SIZE)}])")

def worker(q):
  global time_list
  conn = psycopg2.connect(
    user="postgres",\
    password="postgres",\
    host="127.0.0.1",\
    database="postgres")
  conn.autocommit = True
  cursor = conn.cursor()

  for i in range(int(NUM_OF_WORK / NUM_OF_WORKER / BATCH_SIZE)):
    arr = q.get()
    start_time = time()
    cursor.execute(query, arr)
    res = cursor.fetchone()
    time_list.append(time() - start_time)
    assert len(res[0]) == BATCH_SIZE
    q.task_done()

  conn.close()

  print("returning ...")

if __name__ == '__main__':
  q = Queue()
  
  workers = []
  for i in range(NUM_OF_WORKER):
    t = threading.Thread(
      target=worker, 
      args=(q,))
    t.setDaemon(True)
    t.start()
    workers.append(t)

  conn = psycopg2.connect(
    user="postgres",\
    password="postgres",\
    host="127.0.0.1",\
    database="postgres")
  conn.autocommit = True
  cursor = conn.cursor()

  cursor.execute(f"select id from users LIMIT {NUM_OF_WORK}") # 10^6
  records = cursor.fetchall()
  users = [rec[0] for rec in records]
  shuffle(users)

  print("START WORKING!!!")
  start_time = time()
  for i in range(0, int(NUM_OF_WORK / BATCH_SIZE)):
    q.put(users[i*BATCH_SIZE:i*BATCH_SIZE+BATCH_SIZE])

  cursor.close()
  conn.close()

  q.join()
  print("queue returns ...")
  for w in workers:
    w.join()

  print(f"\nit takes {time() - start_time} seconds")

  print(f"\nmean: {statistics.mean(time_list)}")
  print(f"median: {statistics.median(time_list)}")
  print(f"variance: {statistics.variance(time_list)}")

  print("\ntop 10 lowest duration")
  print(sorted(time_list)[:10])

  print("\ntop 10 highest duration")
  print(sorted(time_list, reverse=True)[:10])
