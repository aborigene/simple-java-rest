package com.example.restservice;

public class Message {

	private final long id;
	private final String message;

	public Message(long id, String message) throws MessageTooLongException {
		try{
			Thread.sleep(5000);
		}
		catch(InterruptedException ex){
			System.out.println ("Error while sleeping...");
		}
		this.id = id;
		//try{
		if (message.length() > 20) {
			throw new MessageTooLongException("Message longer than 20 chars.");
		}
		//}
		this.message = message;
	}

	public Message(long id) {
		String default_message = "Something whent wrong, using default message...";
		String message = default_message;
		try{
			Thread.sleep(5000);
		}
		catch(InterruptedException ex){
			System.out.println ("Error while sleeping...");
		}
		this.id = id;
		this.message = message;
	}

	public long getId() {
		return id;
	}

	public String getMessage() {
		return message;
	}
}
