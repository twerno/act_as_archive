module MyMod
module Acts
   module Roled 
     # included is called from the ActiveRecord::Base
     # when you inject this module

     def self.included(base) 
      # Add acts_as_roled availability by extending the module
      # that owns the function.
       base.extend AddActsAsMethod
     end 

     # this module stores the main function and the two modules for
     # the instance and class functions
     module AddActsAsMethod
       def acts_as_archive(options = {})
        # Here you can put additional association for the
        # target class.
        # belongs_to :role
        # add class and istance methods

          def set_user_stamp stamp
    @user_stamp ||= stamp
  end

         class_eval <<-END
           include MyMod::Acts::Roled::InstanceMethods    
         END
       end
     end

     # Istance methods
     module InstanceMethods 
      # doing this our target class
      # acquire all the methods inside ClassMethods module
      # as class methods.

@@separator = '|!|'
  @@zamiennik = "&#124;&#33;&#124;"
  
  ## umiejszcza objekt w archiwum przed jego zapisaniem 
  def save
    temp = eval(self.class.name.to_s + ".find(" + self.id.to_s + ")") unless self.new_record? ## moze to zmienic, zeby nie odwolywac sie dodatkowo do bazy ? ;)
    
    ##DO ZMIANY PO ZAINSTALOWANIU BORTA 
    self.user_id = 33               
    #self.user_id = current_user.id
    self.user_stamp = @user_stamp
   
    wrk1 = self.changed? & !self.new_record?
    wrk2 = super

    archiving temp unless !(wrk1 & wrk2)
 
    wrk2
  end
  
  
  ## objekty nie sa uzuwane, pole destroyed jest ustawiane na true
  def destroy
    self.destroyed = true
    save
  end
  
  
  def set_user_stamp stamp
    @user_stamp ||= stamp
  end
  
  ## zwraca wszystkie 
  def archives
    rebuild_from_archive Archive.find(:all, :conditions => ["class_name = ? AND class_id = ?", self.class.name, self.id.to_s])
  end
  
  
  ## dodaje objekt do archiwum
  private
  def archiving temp
    archive = Archive.new
    archive.class_name      = temp.class.name
    archive.class_id        = temp.id.to_s
    archive.user_id         = temp.user_id
    archive.user_stamp      = temp.user_stamp
    archive.body            = ""
    archive.body_destroyed  = temp.destroyed
    archive.body_updated_at = temp.updated_at
    
    keys = temp.class.columns.collect{|c| c.name}
    for key in ["id", "user_id", "user_stamp", "destroyed", "updated_at"]
      keys.delete key
    end

    for key in keys
      archive.body << key << @@separator
      archive.body << eval("temp." << key).to_s.gsub(@@separator, @@zamiennik)
      archive.body << @@separator
    end
    
    archive.save
  end

  private
  def rebuild_from_archive set
    
    ## tworzymy pusty zbior
    empty_set = "".to_set
    
    ## dla kazdej elementu w zbiorze
    for anything in set
      
      ## tworzymy nowy objekt i uzupełniamy, pola ktore sa wymagane w kazdym obiekcie
      temp            = eval(anything.class_name << ".new")
      temp.id         = anything.class_id
      temp.user_id    = anything.user_id
      temp.user_stamp = anything.user_stamp
      temp.destroyed  = anything.body_destroyed
      temp.updated_at = anything.body_updated_at
      
      #tworzymy liste wszystkich pol w klasie
      keys  = temp.class.columns.collect{|c| c.name}
      types = temp.class.columns.collect{|c| c.sql_type}
      
      ## i usuwany z tej listy pola juz uzupelnione
      for key in ["id", "user_id", "user_stamp", "destroyed", "updated_at"]
        index = keys.index key
        types.delete_at index unless index.nil?
        keys.delete_at  index unless index.nil?
      end
      
      ## tworzymy liste pol i wartosci z archiwum
      body_split = anything.body.split @@separator
      body_fields_names = []
      body_fields_values= []
      for i in 0..body_split.size/2-1
        body_fields_names  += body_split[2*i].to_a
        value = body_split[2*i+1]
        body_fields_values += (value.nil? || value.empty?) ? [nil] : value.to_a
      end

      ## wpisujemy wartosci z archiwum do odpowiednich pol, dbajac o zachowanie typu
      for key in keys
        if body_fields_names.include? key
          case types[keys.index( key)]
            when "character varying(255)" || "text"
                str = body_fields_values[body_fields_names.index( key)]
                str = (str.nil? || str.empty?) ? "" : str.gsub(@@zamiennik, @@separator)
                eval("temp." << key << "= '" << str <<"'.to_s")
            when "integer"
                int = body_fields_values[body_fields_names.index( key)]
                int = (int.nil? || int.empty?) ? "nil" : int
                eval("temp." << key << "= '" << int <<"'.to_i")
            when "boolean"
                bool = "nil"
                wnk = body_fields_values[body_fields_names.index( key)]       
                bool = (wnk == "true") ? "true" : "false" unless wnk.nil? || wnk.empty?
                eval("temp." << key << "=" << bool)
            when "timestamp without time zone"
                date = body_fields_values[body_fields_names.index( key)]
                eval("temp." << key << "= '" << ((date.nil? || date.empty?) ? "'" : date << "'.to_datetime"))
            when "date"
                date = body_fields_values[body_fields_names.index( key)]
                eval("temp." << key << "= '" << ((date.nil? || date.empty?) ? "'" : date << "'.to_date"))
            when "time without time zone"
                date = body_fields_values[body_fields_names.index( key)]
                eval("temp." << key << "= '" << ((date.nil? || date.empty?) ? "'" : date << "'.to_time"))
            end
        end
      end
      
      ## wrzucamy obiekt do zbioru (set)
      empty_set.add temp
    end
    
    ## zwracamy gotowy zbior
    empty_set
  end



       def self.included(aClass)
         aClass.extend ClassMethods
       end 

       module ClassMethods
         # Class methods  
         # Our random function.
        def random
            find(:first,order=>"RAND()");
        end


       end 

     end 
   end
end
end 