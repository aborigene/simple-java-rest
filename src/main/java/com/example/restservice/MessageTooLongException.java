package com.example.restservice;	

public class MessageTooLongException extends Exception { 
    public MessageTooLongException(String errorMessage) {
        super(errorMessage);
    }
}
