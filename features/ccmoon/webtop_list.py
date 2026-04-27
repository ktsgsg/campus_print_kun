class webtop_list:
   baseurl = ""
   mac_applies = "user/mac_applies/index/2/"
   print_service = "user/"
   record_system = "pcsweb/"
   ebook_lib = "elib/html/BookList?1="
   
   __hostname = "https://ccmoon2.meijo-u.ac.jp"
   
   def __init__(self,baseurl="/f5-w-<REDACTED_BACKEND_URL_HEX>$$/"):
      self.baseurl = baseurl
   
   def get_url_mac(self):
      return self.__hostname + self.baseurl + self.mac_applies
   def get_url_print(self):
      return self.__hostname + self.baseurl + self.print_service
   def get_url_record(self):
      return self.__hostname + self.baseurl + self.record_system
   def get_url_ebook(self):
      return self.__hostname + self.baseurl + self.ebook_lib