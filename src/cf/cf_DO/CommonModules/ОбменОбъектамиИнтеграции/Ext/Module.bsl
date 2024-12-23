﻿
#Область РегистрацияОбъектовДляОбмена

Процедура ЗарегистрироватьОбъект(НаборЗаписей) Экспорт  
	
	УстановитьПривилегированныйРежим(Истина);
		
	Для каждого нЗапись Из НаборЗаписей Цикл
				
		МенеджерЗаписи = РегистрыСведений.ОбъектыИнтеграции.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.СсылкаНаОбъект  = нЗапись.Документ;
		МенеджерЗаписи.ДатаИзменения = ТекущаяУниверсальнаяДатаВМиллисекундах();		
		МенеджерЗаписи.Состояние = нЗапись.Состояние;
		МенеджерЗаписи.Записать();	
		
	КонецЦикла;
	
	УстановитьПривилегированныйРежим(Ложь);
	
КонецПроцедуры

Процедура ДобавлениеОбъектовИнтеграцииПриЗаписи(Источник, Отказ) Экспорт 
	
	Если Источник.ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	
	Если Не ЗначениеЗаполнено(Источник.Ссылка) Тогда
		Возврат;
	КонецЕсли;	
	
	Если Источник.ДополнительныеСвойства.Свойство("ПолученПриОбмене") 
		И Источник.ДополнительныеСвойства.ПолученПриОбмене Тогда
		Возврат;
	КонецЕсли;
	 
	УстановитьПривилегированныйРежим(Истина);
	
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ОбъектыИнтеграции.СсылкаНаОбъект КАК СсылкаНаОбъект
	|ИЗ
	|	РегистрСведений.ОбъектыИнтеграции КАК ОбъектыИнтеграции
	|ГДЕ
	|	ОбъектыИнтеграции.СсылкаНаОбъект = &СсылкаНаОбъектДО";
	
	Запрос.УстановитьПараметр("СсылкаНаОбъектДО", Источник.Ссылка);
	РезультатЗапроса = Запрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
		НаборЗаписей = РегистрыСведений.ОбъектыИнтеграции.СоздатьМенеджерЗаписи();
		НаборЗаписей.СсылкаНаОбъект = Источник.Ссылка;
		НаборЗаписей.ДатаИзменения = ТекущаяУниверсальнаяДатаВМиллисекундах();
		НаборЗаписей.Состояние = Перечисления.СостояниеОбъектовИнтеграции.Ожидает;
		
	Иначе
		НаборЗаписей = РегистрыСведений.ОбъектыИнтеграции.СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.СсылкаНаОбъект.Установить(Источник.Ссылка);
		НаборЗаписей.Прочитать();
		Для каждого запись Из НаборЗаписей Цикл
			запись.ДатаИзменения = ТекущаяУниверсальнаяДатаВМиллисекундах();
			запись.Состояние = Перечисления.СостояниеОбъектовИнтеграции.Ожидает;
		КонецЦикла;
				
	КонецЕсли;
	
	НаборЗаписей.Записать();
		
	УстановитьПривилегированныйРежим(Ложь);

КонецПроцедуры

Процедура ДобавлениеОбъектовИнтеграцииПередЗаписью(Источник, Отказ) Экспорт 
	
	Если Источник.ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	
	Если Не ЗначениеЗаполнено(Источник.Ссылка) Тогда
		Возврат;
	КонецЕсли;	
			
КонецПроцедуры
	
#КонецОбласти

#Область  ОбменСообщениями

// формирование сообщения для ЗУП о принятых объектах
Процедура ОТУС_СформироватьПакетОбменаПринято(ПолученныеДанные, ОписаниеНастройкиПодключения)
	
	Если ПолученныеДанные.Количество() = 0 Тогда
	    Возврат;
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Истина);
				
	Попытка
		
		мДанные = Новый Массив;
		
		Для каждого эл Из ПолученныеДанные Цикл
			сДокумент = Новый Структура;
			сДокумент.Вставить("GUID", Строка(эл));
			
			мДанные.Добавить(сДокумент);
		КонецЦикла;
		
		
		ДанныеСообщения = Новый Структура;
		ДанныеСообщения.Вставить("ОписаниеНастройкиПодключения", ОписаниеНастройкиПодключения);
		ДанныеСообщения.Вставить("Данные", мДанные);
	
		ОтправитьСообщениеОбменаRebbitMQ(ДанныеСообщения, ОписаниеНастройкиПодключения);
		
	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = '(ОТУС) Синхронизация договоров с 1С:ЗУП'"), УровеньЖурналаРегистрации.Ошибка,
		, , НСтр("ru = 'Не удалось записать файл сообщений о полученных данных '") + ОписаниеОшибки());
		ОтменитьТранзакцию();
		
	КонецПопытки;	
		
КонецПроцедуры

//Запуск ОсновнаяФункцияРегл.задания
Процедура ОТУС_ПолучитьИзменения()Экспорт  
	//получение информации о принятых объектах
	ОТУС_ПолучитьПакетОбмена();
	
	НачалоПодготовки = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
	//получение изменений
	ОТУС_ПолучитьСообщениеОбмена();
	СоздатьСообщениеОбмена(НачалоПодготовки);
КонецПроцедуры

#Область ПолучениеПакетаОбмена

//получение информации о принятых объектах в ЗУП	
Процедура ОТУС_ПолучитьПакетОбмена()  
	
	УстановитьПривилегированныйРежим(Истина);
	
	ДанныеСообщения = ПолучитьСообщениеОбменаRebbitMQ("Принята ЗаявкаНаКомандировку в ЗУП");

	Если Не ЗначениеЗаполнено(ДанныеСообщения) Тогда
	     Возврат;
	КонецЕсли;
	
	ПолученныеДанные = Новый Массив;
		
	Попытка
		НачатьТранзакцию();
		
		мПолученныеДанные = Новый Массив;
		
		ЧтениеJSON = Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(ДанныеСообщения);
		Результат = ПрочитатьJSON(ЧтениеJSON);
		Если Не ТипЗнч(Результат) = Тип("Структура") Тогда
		    Возврат;
		КонецЕсли;
		
		Если Не Результат.Свойство("ОписаниеНастройкиПодключения") Тогда
		    Возврат;
		КонецЕсли;
		Если Не Результат.Свойство("Данные") Тогда
		    Возврат;
		КонецЕсли;
		
		мРезультат = Результат.Данные;
		Если Не ТипЗнч(мРезультат) = Тип("Массив") Тогда
		    Возврат;
		КонецЕсли;
		Если мРезультат.Количество() = 0 Тогда
		    Возврат;
		КонецЕсли;
		
		ОТУС_ЗарегистрироватьПолучениеОбъектов(мРезультат);
		
		ЗафиксироватьТранзакцию();	
		
	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = '(ОТУС) Синхронизация договоров с 1С:ЗУП'"), УровеньЖурналаРегистрации.Ошибка,
		, , НСтр("ru = 'Ошибка получения данных: '") + "ЗУП_ДО_ЗаявкаНаКомандировку_Принято " + ОписаниеОшибки());
		ОтменитьТранзакцию();
		
	КонецПопытки;		
		
КонецПроцедуры

Процедура ОТУС_ЗарегистрироватьПолучениеОбъектов(мРезультат)

	Для Каждого Объект_Документ Из мРезультат Цикл
			ОТУС_ЗарегистрироватьПолучениеОбъектов_Продолжение(Объект_Документ);		
	КонецЦикла;
	

КонецПроцедуры

Процедура ОТУС_ЗарегистрироватьПолучениеОбъектов_Продолжение(Объект_Документ)

	GUID = Объект_Документ.GUID;
	ЗаявкаНаКомандировку = Документы.ЗаявкаНаКомандировку.ПолучитьСсылку(Новый УникальныйИдентификатор(GUID));
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ДР.СсылкаНаОбъект КАК СсылкаНаОбъектДО
		|ИЗ
		|	РегистрСведений.ОбъектыИнтеграции КАК ДР
		|ГДЕ
		|	ДР.СсылкаНаОбъект = &СсылкаНаОбъект
		|	И Не ДР.Состояние = &СостояниеОжидает";
	
	Запрос.УстановитьПараметр("СостояниеОжидает", Перечисления.СостояниеОбъектовИнтеграции.Ожидает);
	Запрос.УстановитьПараметр("СсылкаНаОбъект", ЗаявкаНаКомандировку);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Пока Выборка.Следующий() Цикл
		НаборЗаписей = РегистрыСведений.ОбъектыИнтеграции.СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.СсылкаНаОбъект.Установить(ЗаявкаНаКомандировку);
		НаборЗаписей.Прочитать();
		Для каждого запись Из НаборЗаписей Цикл
			запись.ДатаИзменения = ТекущаяУниверсальнаяДатаВМиллисекундах();
			запись.Состояние = Перечисления.СостояниеОбъектовИнтеграции.Принят;
		КонецЦикла;
		НаборЗаписей.Записать();
		
	КонецЦикла;	
	
КонецПроцедуры

#КонецОбласти

#Область ПолучениеСообщенияОбмена

Процедура ОТУС_ПолучитьСообщениеОбмена()
	
	УстановитьПривилегированныйРежим(Истина);
	
	ДанныеСообщения = ПолучитьСообщениеОбменаRebbitMQ("ЗаявкаНаКомандировку из ЗУП в ДО");
	
	Если Не ЗначениеЗаполнено(ДанныеСообщения) Тогда
	     Возврат;
	КонецЕсли;
	
	ПолученныеДанные = Новый Массив;
	
	Попытка
		НачатьТранзакцию();
		
		мПолученныеДанные = Новый Массив;
		
		ЧтениеJSON = Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(ДанныеСообщения);
		Результат = ПрочитатьJSON(ЧтениеJSON);
		Если Не ТипЗнч(Результат) = Тип("Структура") Тогда
		    Возврат;
		КонецЕсли;
		Если Не Результат.Свойство("Документ_ЗаявкаНаКомандировку") Тогда
		    Возврат;
		КонецЕсли;
		
		мРезультат = Результат.Документ_ЗаявкаНаКомандировку;
		Если Не ТипЗнч(мРезультат) = Тип("Массив") Тогда
		    Возврат;
		КонецЕсли;
		Если мРезультат.Количество() = 0 Тогда
		    Возврат;
		КонецЕсли;
		
		ОТУС_Получить_ЗаявкаНаКомандировку(мРезультат, мПолученныеДанные);
					
		Для каждого эл Из мПолученныеДанные Цикл
			ПолученныеДанные.Добавить(эл);
		КонецЦикла;
		
		// формирование сообщение об обработанных данных
		ОТУС_СформироватьПакетОбменаПринято(ПолученныеДанные, "Принята ЗаявкаНаКомандировку в ДО");
		
		ЗафиксироватьТранзакцию();	
		
	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = '(ОТУС) Синхронизация договоров с 1С:ДО'"), УровеньЖурналаРегистрации.Ошибка,
		, , НСтр("ru = 'Ошибка получения данных из ДО: '") + ОписаниеОшибки());
		ОтменитьТранзакцию();
		
	КонецПопытки;
	
КонецПроцедуры

Процедура ОТУС_Получить_ЗаявкаНаКомандировку(мРезультат, мПолученныеДанные)   

	
	Для Каждого Объект_Документ Из мРезультат Цикл
		ОТУС_ПолучитьДанные_ЗаявкаНаКомандировку(Объект_Документ, мПолученныеДанные);		
	КонецЦикла;
		
	
КонецПроцедуры

Процедура ОТУС_ПолучитьДанные_ЗаявкаНаКомандировку(Объект_Документ, мПолученныеДанные) 
	
		
	GUID = Объект_Документ.GUID;
	
	// Сотрудник
	ДанныеФизЛица =  ОТУС_ПолучитьФизЛицо(Объект_Документ.Сотрудник);
	Если Не ЗначениеЗаполнено(ДанныеФизЛица) Тогда
		Возврат;
	КонецЕсли;
			
	ДатаДокумента = ДатаИзСтроки(Объект_Документ.Дата);
		
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ЗаявкаНаКомандировку.Ссылка КАК Ссылка
	|ИЗ
	|	Документ.ЗаявкаНаКомандировку КАК ЗаявкаНаКомандировку
	|ГДЕ
	|	ЗаявкаНаКомандировку.Номер = &Номер
	|	И НАЧАЛОПЕРИОДА(ЗаявкаНаКомандировку.Дата, ДЕНЬ) = &Дата";
	
	Запрос.УстановитьПараметр("Дата", НачалоДня(ДатаДокумента));
	Запрос.УстановитьПараметр("Номер", Объект_Документ.Номер);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Сумма = ЧислоИзСтроки(Объект_Документ.Сумма);
	
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда	   
		
		ДокументОбъект = Выборка.Ссылка.ПолучитьОбъект();
		
		Обработано = Ложь;
		
		СтруктураДляПоискаФЗ = Новый Структура("Сотрудник", ДанныеФизЛица);
		МассивСтрок = ДокументОбъект.ВыдачаПодОтчет.НайтиСтроки(СтруктураДляПоискаФЗ);
		
		Для каждого Стр Из МассивСтрок Цикл
			Если (стр.Сотрудник = ДанныеФизЛица И Сумма = 0) 
				ИЛИ Обработано Тогда
				ДокументОбъект.ВыдачаПодОтчет.Удалить(стр);
				Обработано = Истина;
				Продолжить;
			КонецЕсли;
			
			Если  стр.Сотрудник = ДанныеФизЛица И Не Сумма = 0 Тогда
			   стр.Сумма = Сумма;
			   Обработано = Истина;
			КонецЕсли;
		КонецЦикла;
		
		Если Не Обработано и Не Сумма = 0 Тогда
		    стр = ДокументОбъект.ВыдачаПодОтчет.Добавить();
			стр.Сотрудник = ДанныеФизЛица;
		    стр.Сумма = Сумма;
		КонецЕсли;
		
		ДокументОбъект.ДополнительныеСвойства.Вставить("ПолученПриОбмене", Истина);
		
		Попытка
			ДокументОбъект.Записать();  
			мПолученныеДанные.Добавить(Объект_Документ.GUID);			
		Исключение
			ШаблонСообщения = НСтр("ru = 'Не удалось записать документ. 
			|Описание ошибки:
			|%1'");
			Сообщение =  СтрШаблон(ШаблонСообщения, ОписаниеОшибки());
			ЗаписьЖурналаРегистрации(НСтр("ru = '(ОТУС) Синхронизация договоров с 1С:ЗУП'"), УровеньЖурналаРегистрации.Ошибка, , , Сообщение);
		КонецПопытки;
		
	Иначе
		//у ДО приоритет. Не создаем заявки на командировк
		
		мПолученныеДанные.Добавить(Объект_Документ.GUID);
	
	КонецЕсли;
	
КонецПроцедуры

Функция ОТУС_ПолучитьФизЛицо(сФизЛицо)

	Если ЗначениеЗаполнено(сФизЛицо.GUID) Тогда
		ФизЛицо = Справочники.ФизическиеЛица.ПолучитьСсылку(Новый УникальныйИдентификатор(сФизЛицо.GUID));
		Если Найти(Строка(ФизЛицо),"Объект не найден") = 0 
			И Найти(Строка(ФизЛицо),"Object not found") = 0 Тогда
			Возврат ФизЛицо;
		КонецЕсли;
	КонецЕсли;
			
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ФЛ.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник.ФизическиеЛица КАК ФЛ
		|ГДЕ
		|	&Условие";
				
	Если ЗначениеЗаполнено(сФизЛицо.СтраховойНомерПФР) Тогда
	     Запрос.Текст = СтрЗаменить(Запрос.Текст, "&Условие", "ФЛ.СтраховойНомерПФР = &СтраховойНомерПФР");
		 Запрос.УстановитьПараметр("СтраховойНомерПФР", сФизЛицо.СтраховойНомерПФР);
	ИначеЕсли ЗначениеЗаполнено(сФизЛицо.ИНН) Тогда
	     Запрос.Текст = СтрЗаменить(Запрос.Текст, "&Условие", "ФЛ.ИНН = &ИНН");
		 Запрос.УстановитьПараметр("ИНН", сФизЛицо.ИНН);
	Иначе
		 Запрос.Текст = СтрЗаменить(Запрос.Текст, "&Условие", "ФЛ.Фамилия = &Фамилия
																 |	И ФЛ.Имя = &Имя
																 |	И ФЛ.Отчество = &Отчество");
		 Запрос.УстановитьПараметр("Фамилия", сФизЛицо.Фамилия);
		 Запрос.УстановитьПараметр("Имя", сФизЛицо.Имя);
		 Запрос.УстановитьПараметр("Отчество", сФизЛицо.Отчество);
		 
	КонецЕсли;
		
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда
	    Возврат Выборка.Ссылка;
	Иначе	
		ФизЛицоОбъект = Справочники.ФизическиеЛица.СоздатьЭлемент();
		Если ЗначениеЗаполнено(сФизЛицо.GUID) Тогда
			УникальныйИдентификатор = Новый УникальныйИдентификатор(сФизЛицо.GUID);
			Ссылка = Справочники.ФизическиеЛица.ПолучитьСсылку(УникальныйИдентификатор);
			ФизЛицоОбъект.УстановитьСсылкуНового(Ссылка);
		КонецЕсли;
		ФизЛицоОбъект.ФИО = сФизЛицо.Фамилия + ?(ЗначениеЗаполнено(сФизЛицо.Имя)," " +  сФизЛицо.Имя, "") + ?(ЗначениеЗаполнено(сФизЛицо.Отчество)," " +  сФизЛицо.Отчество, "");
		ФизЛицоОбъект.Наименование = ФизЛицоОбъект.ФИО;
		
		ФизЛицоОбъект.Фамилия = сФизЛицо.Фамилия;
		ФизЛицоОбъект.Имя = сФизЛицо.Имя;
		ФизЛицоОбъект.Отчество = сФизЛицо.Отчество;
		
		ФизЛицоОбъект.ИНН = сФизЛицо.ИНН;
		ФизЛицоОбъект.СтраховойНомерПФР = сФизЛицо.СтраховойНомерПФР;
	
		Попытка
			ФизЛицоОбъект.Записать();
			Возврат ФизЛицоОбъект.Ссылка;
		Исключение
			ЗаписьЖурналаРегистрации(НСтр("ru = '(ОТУС) Синхронизация договоров с 1С:ДО'"), УровеньЖурналаРегистрации.Ошибка,
			, , НСтр("ru = 'Ошибка создания физ.лица: '") + ОписаниеОшибки());
			Возврат Неопределено;
		КонецПопытки;
		
	КонецЕсли;
	

КонецФункции // ()

#КонецОбласти

#Область СозданиеСообщенияОбмена

Процедура СоздатьСообщениеОбмена(НачалоПодготовки)
	
	УстановитьПривилегированныйРежим(Истина);
			
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	рт_ОбъектыИнтеграции.СсылкаНаОбъект КАК СсылкаНаОбъектДО
		|ПОМЕСТИТЬ СписокОбъекты
		|ИЗ
		|	РегистрСведений.ОбъектыИнтеграции КАК рт_ОбъектыИнтеграции
		|ГДЕ
		|	рт_ОбъектыИнтеграции.Состояние = ЗНАЧЕНИЕ(Перечисление.СостояниеОбъектовИнтеграции.Ожидает)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ДД.Ссылка КАК Ссылка,
		|	ДД.Номер КАК Номер,
		|	ДД.Дата КАК Дата,
		|	ДД.ПометкаУдаления КАК ПометкаУдаления,
		|	ДД.Проведен КАК Проведен,
		|	ДД.Организация КАК Организация,
		|	ДД.Сотрудник КАК Сотрудник,
		|	ДД.ДатаНачала КАК ДатаНачала,
		|	ДД.ДатаОкончания КАК ДатаОкончания,
		|	ДД.МестоНазначения КАК МестоНазначения,
		|	ДД.Партнер КАК Партнер,
		|	ДД.Цель КАК Цель,
		|	ДД.Статус КАК Статус,
		|	ДД.КтоРешил КАК КтоРешил,
		|	ДД.БронироватьБилетыТуда КАК БронироватьБилетыТуда,
		|	ДД.БронироватьБилетыОбратно КАК БронироватьБилетыОбратно,
		|	ДД.БронироватьПроживание КАК БронироватьПроживание,
		|	ДД.Закрыта КАК Закрыта,
		|	ДД.ДатаРассмотрения КАК ДатаРассмотрения
		|ПОМЕСТИТЬ ДД
		|ИЗ
		|	СписокОбъекты КАК СписокОбъекты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗаявкаНаКомандировку КАК ДД
		|		ПО СписокОбъекты.СсылкаНаОбъектДО = ДД.Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	КомандируемыеСотрудники.Ссылка КАК Ссылка,
		|	КомандируемыеСотрудники.Сотрудник КАК Сотрудник
		|ПОМЕСТИТЬ СписокКомандируемых
		|ИЗ
		|	СписокОбъекты КАК СписокОбъекты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗаявкаНаКомандировку.КомандируемыеСотрудники КАК КомандируемыеСотрудники
		|		ПО СписокОбъекты.СсылкаНаОбъектДО = КомандируемыеСотрудники.Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ДД.Ссылка КАК СсылкаНаОбъектДО,
		|	ДД.Номер КАК Номер,
		|	ДД.Дата КАК Дата,
		|	ДД.ПометкаУдаления КАК ПометкаУдаления,
		|	ДД.Проведен КАК Проведен,
		|	ДД.Организация КАК Организация,
		|	ЕСТЬNULL(Организации.ИНН, ВЫРАЗИТЬ("""" КАК СТРОКА(12))) КАК ОрганизацияИНН,
		|	ЕСТЬNULL(Организации.КПП, ВЫРАЗИТЬ("""" КАК СТРОКА(9))) КАК ОрганизацияКПП,
		|	ЕСТЬNULL(Организации.Наименование, ВЫРАЗИТЬ("""" КАК СТРОКА(50))) КАК ОрганизацияНаименование,
		|	ЕСТЬNULL(СписокКомандируемых.Сотрудник, ДД.Сотрудник) КАК Сотрудник,
		|	ДД.ДатаНачала КАК ДатаНачала,
		|	ДД.ДатаОкончания КАК ДатаОкончания,
		|	ДД.МестоНазначения КАК МестоНазначения,
		|	ДД.Партнер КАК Партнер,
		|	ЕСТЬNULL(Контрагенты.Наименование, ВЫРАЗИТЬ("""" КАК СТРОКА(100))) КАК ОрганизацияНазначения,
		|	ДД.Цель КАК Цель,
		|	ДД.Статус КАК Статус,
		|	ДД.Закрыта КАК Закрыта,
		|	ЕСТЬNULL(Пользователи.Наименование, ВЫРАЗИТЬ("""" КАК СТРОКА(100))) КАК КтоРешил,
		|	ДД.БронироватьБилетыТуда КАК БронироватьБилетыТуда,
		|	ДД.БронироватьБилетыОбратно КАК БронироватьБилетыОбратно,
		|	ДД.БронироватьПроживание КАК БронироватьПроживание,
		|	ДД.ДатаРассмотрения КАК ДатаРассмотрения
		|ПОМЕСТИТЬ ВТ_ОсновныеДанные
		|ИЗ
		|	ДД КАК ДД
		|		ЛЕВОЕ СОЕДИНЕНИЕ СписокКомандируемых КАК СписокКомандируемых
		|		ПО ДД.Ссылка = СписокКомандируемых.Ссылка
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО ДД.Организация = Организации.Ссылка
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Пользователи КАК Пользователи
		|		ПО ДД.КтоРешил = Пользователи.Ссылка
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Контрагенты КАК Контрагенты
		|		ПО ДД.Партнер = Контрагенты.Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ДД.СсылкаНаОбъектДО КАК СсылкаНаОбъектДО,
		|	ДД.Номер КАК Номер,
		|	ДД.Дата КАК Дата,
		|	ДД.ПометкаУдаления КАК ПометкаУдаления,
		|	ДД.Проведен КАК Проведен,
		|	ДД.Организация КАК Организация,
		|	ДД.ОрганизацияИНН КАК ОрганизацияИНН,
		|	ДД.ОрганизацияКПП КАК ОрганизацияКПП,
		|	ДД.ОрганизацияНаименование КАК ОрганизацияНаименование,
		|	ДД.Сотрудник КАК Сотрудник,
		|	ДД.ДатаНачала КАК ДатаНачала,
		|	ДД.ДатаОкончания КАК ДатаОкончания,
		|	ДД.МестоНазначения КАК МестоНазначения,
		|	ДД.Партнер КАК Партнер,
		|	ЕСТЬNULL(ФизическиеЛица.Фамилия, ВЫРАЗИТЬ("""" КАК СТРОКА(50))) КАК Фамилия,
		|	ЕСТЬNULL(ФизическиеЛица.Имя, ВЫРАЗИТЬ("""" КАК СТРОКА(50))) КАК Имя,
		|	ЕСТЬNULL(ФизическиеЛица.Отчество, ВЫРАЗИТЬ("""" КАК СТРОКА(50))) КАК Отчество,
		|	ЕСТЬNULL(ФизическиеЛица.ИНН, ВЫРАЗИТЬ("""" КАК СТРОКА(12))) КАК ИНН,
		|	ЕСТЬNULL(ФизическиеЛица.СтраховойНомерПФР, ВЫРАЗИТЬ("""" КАК СТРОКА(10))) КАК СтраховойНомерПФР,
		|	ДД.ОрганизацияНазначения КАК ОрганизацияНазначения,
		|	ДД.Цель КАК Цель,
		|	ДД.Статус КАК Статус,
		|	ДД.Закрыта КАК Закрыта,
		|	ДД.КтоРешил КАК КтоРешил,
		|	ДД.БронироватьБилетыТуда КАК БронироватьБилетыТуда,
		|	ДД.БронироватьБилетыОбратно КАК БронироватьБилетыОбратно,
		|	ДД.БронироватьПроживание КАК БронироватьПроживание,
		|	ДД.ДатаРассмотрения КАК ДатаРассмотрения
		|ИЗ
		|	ВТ_ОсновныеДанные КАК ДД
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.ФизическиеЛица КАК ФизическиеЛица
		|		ПО ДД.Сотрудник = ФизическиеЛица.Ссылка";
			
	РезультатЗапроса = Запрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
	    ЗаписьЖурналаРегистрации(НСтр("ru = '(РТК) Синхронизация договоров с 1С:ЗУП'"), УровеньЖурналаРегистрации.Информация,
					, , НСтр("ru = 'Нет данных для отправки'"));
		Возврат;
	КонецЕсли;
							
	НачатьТранзакцию();		

	Попытка
		мДанные = Новый Массив;
				
		Выборка = РезультатЗапроса.Выбрать();
		
		Пока Выборка.Следующий() Цикл
			сДокумент = Новый Структура;
			//сДокумент.Вставить("", );
			
			GUID = GUIDПоСсылке(Выборка.СсылкаНаОбъектДО);
			сДокумент.Вставить("GUID"						, Строка(GUID));
			
			сДокумент.Вставить("Номер"						, Выборка.Номер);
			сДокумент.Вставить("Дата"						, ПредставлениеДаты(Выборка.Дата));
			сДокумент.Вставить("ПометкаУдаления"			, ПредставлениеБулево(Выборка.ПометкаУдаления));
			сДокумент.Вставить("Проведен"					, ПредставлениеБулево(Выборка.Проведен));
			сДокумент.Вставить("Статус"						, ПредставлениеПеречисления(Выборка.Статус));
			сДокумент.Вставить("ДатаРассмотрения"			, ПредставлениеПеречисления(Выборка.ДатаРассмотрения));
			сДокумент.Вставить("Закрыта"					, ПредставлениеБулево(Выборка.Закрыта));
									
			GUID = GUIDПоСсылке(Выборка.Организация);
			сОрганизация = Новый Структура;
			сОрганизация.Вставить("Организация_GUID"		, Строка(GUID));
			сОрганизация.Вставить("Организация_ИНН"			, Выборка.ОрганизацияИНН);
		    сОрганизация.Вставить("ОрганизацияКПП"			, Выборка.ОрганизацияКПП);
		    сОрганизация.Вставить("ОрганизацияНаименование"	, Выборка.ОрганизацияНаименование);
		    сДокумент.Вставить("Организация"				, сОрганизация);
			
			сДокумент.Вставить("ОрганизацияНазначения"		, Выборка.ОрганизацияНазначения);
			сДокумент.Вставить("Цель"						, Выборка.Цель);
			сДокумент.Вставить("КтоРешил"					, Выборка.КтоРешил);
		    сДокумент.Вставить("МестоНазначения"			, Выборка.МестоНазначения);
		
            сДокумент.Вставить("ДатаНачала"					, ПредставлениеДаты(Выборка.ДатаНачала));
			сДокумент.Вставить("ДатаОкончания"				, ПредставлениеДаты(Выборка.ДатаОкончания));
			
            GUID = GUIDПоСсылке(Выборка.Сотрудник);
			сСотрудник = Новый Структура;			
			сСотрудник.Вставить("GUID"			, Строка(GUID));			
			сСотрудник.Вставить("Фамилия"			, Выборка.Фамилия);
		    сСотрудник.Вставить("Имя"				, Выборка.Имя);
		    сСотрудник.Вставить("Отчество"		, Выборка.Отчество);
		    сСотрудник.Вставить("ИНН"				, Выборка.ИНН);
		    сСотрудник.Вставить("СтраховойНомерПФР", Выборка.СтраховойНомерПФР);
			
			сДокумент.Вставить("Сотрудник"					, сСотрудник);
			
			сДокумент.Вставить("БронироватьБилетыТуда"		, ПредставлениеБулево(Выборка.БронироватьБилетыТуда));
			сДокумент.Вставить("БронироватьБилетыОбратно"	, ПредставлениеБулево(Выборка.БронироватьБилетыОбратно));
			сДокумент.Вставить("БронироватьПроживание"		, ПредставлениеБулево(Выборка.БронироватьПроживание));
			
			//сДокумент.Вставить("Сумма"							, ПредставлениеЧисла(Выборка.Сумма));			
				
			мДанные.Добавить(сДокумент);
		КонецЦикла;
		
		ДанныеСообщения = Новый Структура;
		ДанныеСообщения.Вставить("Документ_ЗаявкаНаКомандировку", мДанные);
		
		ОтправитьСообщениеОбменаRebbitMQ(ДанныеСообщения, "ЗаявкаНаКомандировку из ДО в ЗУП");
		
		Выборка.Сбросить();
		Пока Выборка.Следующий() Цикл
		НаборЗаписей = РегистрыСведений.ОбъектыИнтеграции.СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.СсылкаНаОбъект.Установить(Выборка.СсылкаНаОбъектДО);
		НаборЗаписей.Прочитать();
		Для каждого запись Из НаборЗаписей Цикл
			запись.ДатаИзменения = ТекущаяУниверсальнаяДатаВМиллисекундах();
			запись.Состояние = Перечисления.СостояниеОбъектовИнтеграции.Отправлен;
		КонецЦикла;
		НаборЗаписей.Записать();
		
	КонецЦикла;
		
	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = '(РТК) Синхронизация заявки на командировку 1С:ЗУП'"), УровеньЖурналаРегистрации.Ошибка,
		, , НСтр("ru = 'Не удалось отправит файл сообщений '") + ОписаниеОшибки());
		ОтменитьТранзакцию();
	КонецПопытки;
	
	ЗафиксироватьТранзакцию();
	
	УстановитьПривилегированныйРежим(Ложь);
КонецПроцедуры

#Область СозданиеСообщенияОбмена_ВспомогательныеПроцедурыФункции

Функция ПредставлениеДаты(Значение)
	//Возврат Формат(Значение, "ДЛФ=DT");
	Возврат Формат(Значение, "ДФ='yyyyMMddhhmmss'");
КонецФункции

Функция ПредставлениеБулево(Значение)
	Возврат ?(Значение, "ИСТИНА", "ЛОЖЬ");
КонецФункции

Функция ПредставлениеЧисла(Значение)
	Возврат Формат(Значение, "ЧГ=");
КонецФункции

Функция GUIDПоСсылке(Значение)
	Возврат Значение.УникальныйИдентификатор();
КонецФункции

Функция СсылкаПоGUID(GUID, Тип = Неопределено)
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ПубличныеИдентификаторыСинхронизируемыхОбъектов.Ссылка КАК Ссылка
	|ИЗ
	|	РегистрСведений.ПубличныеИдентификаторыСинхронизируемыхОбъектов КАК ПубличныеИдентификаторыСинхронизируемыхОбъектов
	|ГДЕ
	|	ПубличныеИдентификаторыСинхронизируемыхОбъектов.Идентификатор = &Идентификатор
	|	И (&БезОтбораПоТипам
	|		ИЛИ ТИПЗНАЧЕНИЯ(ПубличныеИдентификаторыСинхронизируемыхОбъектов.Ссылка) = &Тип)";
	Запрос.УстановитьПараметр("Идентификатор", GUID);
	Запрос.УстановитьПараметр("БезОтбораПоТипам", Тип = Неопределено);
	Запрос.УстановитьПараметр("Тип", Тип);
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда 
		Возврат Выборка.Ссылка;
	КонецЕсли;
		
	Возврат Неопределено
КонецФункции

Функция ПредставлениеПеречисления(Значение, ИмяПеречисления = "СостоянияДокументов")
	
	результат = "";
	
	Если ЗначениеЗаполнено(Значение) Тогда 
		результат = Строка(Значение);
	КонецЕсли;
	
	Возврат результат;
	
КонецФункции	

Функция ЧислоИзСтроки(Значение)
	Возврат ?(ПустаяСтрока(Значение), 0, Число(Значение));
КонецФункции

Функция ДатаИзСтроки(Значение)
	Возврат ?(ПустаяСтрока(Значение), '00010101', Дата(Значение));
КонецФункции

#КонецОбласти

 #Область ОтправитьСообщениеRebbitMQ
 
 Процедура ОтправитьСообщениеОбменаRebbitMQ(Данные, ДопУсловие = "")
 
 	Настройки = RebbitMQСервер.ПолучитьНастройкиПодключенияИзРегистра(ДопУсловие);
	
	Компонента = RebbitMQСервер.ПолучитьКомпоненту();
	
	ТекстJSON = RebbitMQКлиентСервер.СериализоватьВJSON(Данные);		
	
	RebbitMQКлиентСервер.ОтправитьСообщение(Компонента, Настройки, ТекстJSON);
 
 КонецПроцедуры // ()
 
 Функция ПолучитьСообщениеОбменаRebbitMQ(ДопУсловие = "")
 
 	Настройки = RebbitMQСервер.ПолучитьНастройкиПодключенияИзРегистра(ДопУсловие);
	
	Компонента = RebbitMQСервер.ПолучитьКомпоненту();
	
	ДанныеСообщения = RebbitMQКлиентСервер.ПрочитатьСообщение(Компонента, Настройки);
	
	Возврат  ДанныеСообщения;
	
КонецФункции

#КонецОбласти

#КонецОбласти

#КонецОбласти