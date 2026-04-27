import time
def gen_f5_st(f5_st):
   #unix時間を取得
   f5_st_part = f5_st.split("z")[3]
   unix_time = f5_st_part
   admIdleTimeout = 3600
   admGuardTime = 100
   sessionstart = unix_time
   maxTimeout = 604800
   maxGuardTime = 600
   
   F5_ST=f"{unix_time}c{admIdleTimeout}c{admGuardTime}c{sessionstart}c{maxTimeout}c{maxGuardTime}c"
   return F5_ST