package com.example.restservice;
import java.util.Random;

public class Greeting {

	private final String id;
	private final String content;

	public Greeting(String id, String content) {
		try{
			Random rand = new Random(); //instance of random class
      			int upperbound = 25;
        		//generate random values from 0-24
      			int int_random = rand.nextInt(upperbound)*1000;
			System.out.println("Waiting for "+int_random+" seconds.");
			Thread.sleep(int_random);
		}
		catch(InterruptedException ex){
			System.out.println ("Error while sleeping...");
		}
		this.id = id;
		this.content = content;
	}

	public long getId() {
		return Long.parseLong(id);
	}

	public String getContent() {
		return content;
	}
}
