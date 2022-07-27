package com.example.restservice;
import java.util.Random;

public class Greeting {

	private final String id;
	private final String content;
	private Integer value;
	private Integer fixed_value=1;
	private Integer error;

	public Greeting(String id, String content) {
		int int_random = 0;
		//try{
			Random rand = new Random(); //instance of random class
      			int upperbound = 25;
        		//generate random values from 0-24
      			int_random = rand.nextInt(upperbound);//*1000;
			//System.out.println("Waiting for "+int_random+" seconds.");
			//Thread.sleep(int_random);
		//}
		/*catch(InterruptedException ex){
			System.out.println ("Error while sleeping...");
		}*/
		System.out.println("Starting to create stuff...");
		this.id = id;
		this.content = content;
		this.value = int_random;
		if (int_random == 14) this.error = 1;
		else this.error = 0;
		System.out.println("Finished to create stuff...");
	}

	public String getId() {
		return id;
	}

	public String getContent() {
		return content;
	}

	public Integer getValor() {
		return value;
	}

	public Integer getValorFixo() {
		return fixed_value;
	}

	public Integer getError() {
		return error;
	}
}
