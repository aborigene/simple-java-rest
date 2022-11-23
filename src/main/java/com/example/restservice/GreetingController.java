package com.example.restservice;

import java.util.concurrent.atomic.AtomicLong;

import java.lang.*;
import java.util.UUID;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CookieValue;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.datasource.SimpleDriverDataSource;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.SQLException;

@RestController
public class GreetingController {

	private static final String template = "Hello, %s!";
	private static final String message_template = "This is the messge: %s!";
	private final AtomicLong counter = new AtomicLong();
	private final AtomicLong counterMessage = new AtomicLong();

//SimpleDriverDataSource dataSource = new SimpleDriverDataSource();
 //   dataSource.setDriver(new com.mysql.jdbc.Driver());
   // dataSource.setUrl("jdbc:mysql://34.204.189.65/messages_db");
    //dataSource.setUsername("message_user");
    //dataSource.setPassword("testmessage123!");
         
    //JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);

	@CrossOrigin(origins = "*")
	@GetMapping("/greeting")
	public Greeting greeting(@RequestParam(value = "name", defaultValue = "World") String name){//, JdbcTemplate jt) {
		/*String sqlInsert = "insert into message_table (ID, UserName, MessageTime)"
				+ " VALUES (?, ?, ?)";*/
		UUID uuid = UUID.randomUUID();
		
//		jt.update(sqlInsert, uuid.toString(), String.format(template, name), System.currentTimeMillis());
		System.out.println(String.format(template, name));
		return new Greeting(uuid.toString(), String.format(template, name));
	}

	@CrossOrigin(origins = "*")
	@GetMapping("/sortear")
	public Sorteio sorteio(){
		return new Sorteio();
	}

	@CrossOrigin(origins = "*")
	@GetMapping("/message")
	public Message message(@RequestParam(value = "message", defaultValue = "SOME MESSAGE...") String message, @CookieValue(value = "dtCookie", defaultValue = "not-set") String dtCookie, @RequestParam(value = "record_id") String record_id){//, JdbcTemplate jt){
		System.out.println(String.format(template, message));
		System.out.println("This is the dtCookie:");
		System.out.println(dtCookie);

		/*String sqlUpdate = "update table message_table set message = ? where id = ?";
		
		jt.update(sqlUpdate, String.format(message_template, message), record_id);

		try{
			return new Message(counterMessage.incrementAndGet(), String.format(message_template, message));
		}
		catch(Exception e){
			return new Message(counterMessage.incrementAndGet());
		}*/
		return  new Message(counterMessage.incrementAndGet());
	}
}
