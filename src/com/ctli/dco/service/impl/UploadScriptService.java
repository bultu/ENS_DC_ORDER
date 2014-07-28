package com.ctli.dco.service.impl;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import com.ctli.dco.service.IUploadScriptService;
import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;

public class UploadScriptService implements IUploadScriptService {
	JSch jsch = new JSch();
	String command = "pwd";

	String SFTPHOST = "lamare24";
	int SFTPPORT = 22;
	String SFTPUSER = "prcoper";
	String SFTPPASS = "trypet1";
	String SFTPWORKINGDIR = "dc_order_tool";

	Session session = null;
	Channel channel = null;
	Channel channelExec = null;
	ChannelSftp channelSftp = null;

	public String uploadScript(String type, String scriptName) {
		String status = "Uploaded Sucessfully at ";
		try {

			String scriptPath = "combinedScript/" + type + "/" + scriptName;
			JSch jsch = new JSch();
			session = jsch.getSession(SFTPUSER, SFTPHOST, SFTPPORT);
			session.setPassword(SFTPPASS);
			java.util.Properties config = new java.util.Properties();
			config.put("StrictHostKeyChecking", "no");
			session.setConfig(config);
			session.connect();
			channel = session.openChannel("sftp");
			channelExec = session.openChannel("shell");
			OutputStream ops = channelExec.getOutputStream();
			PrintStream ps = new PrintStream(ops, true);
			channel.connect();
			channelExec.connect();

			channelSftp = (ChannelSftp) channel;

			System.out.println(channelSftp.pwd());
			channelSftp.cd(SFTPWORKINGDIR);
			status += channelSftp.pwd();
			File f = new File(scriptPath);
			FileInputStream fiStream = new FileInputStream(f);
			channelSftp.put(fiStream, f.getName());

			ps.println("cd dc_order_tool");
			ps.println("d2u.sh " + f.getName());
			ps.close();

			fiStream.close();
		} catch (Exception ex) {
			status = ex.getMessage();
			System.out.println(ex.getMessage());
		} finally {
			channelExec.disconnect();
			channelSftp.disconnect();
			channel.disconnect();
			session.disconnect();
			moveToOld(type, scriptName);
 
		}
		return status;
	}

	private void moveToOld(String type, String scriptName) {
		CompareIssueService csService = new CompareIssueService();
		String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(Calendar.getInstance().getTime());
		File oldFile = new File("combinedScript/" + type + "/OLD/" + scriptName+"_"+timeStamp);
		File file = new File("combinedScript/" + type + "/" + scriptName);
		csService.moveFile(file, oldFile);
		
	}
	

}
