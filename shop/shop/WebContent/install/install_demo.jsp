<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.Date"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@page import="org.apache.commons.io.FileUtils"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="org.apache.commons.lang.time.DateUtils"%>
<%@page import="net.shopxx.util.FreemarkerUtils"%>
<%@page import="net.shopxx.util.JsonUtils"%>
<%@include file="common.jsp"%>
<%
	Boolean isAgreeAgreement = (Boolean) session.getAttribute("isAgreeAgreement");
	if (isAgreeAgreement == null || !isAgreeAgreement) {
		response.sendRedirect("index.jsp");
		return;
	}

	String databaseType = (String) session.getAttribute("databaseType");
	String databaseHost = (String) session.getAttribute("databaseHost");
	String databasePort = (String) session.getAttribute("databasePort");
	String databaseUsername = (String) session.getAttribute("databaseUsername");
	String databasePassword = (String) session.getAttribute("databasePassword");
	String databaseName = (String) session.getAttribute("databaseName");
	String isInitializeDemo = (String) session.getAttribute("isInitializeDemo");

	String status = "success";
	String message = "";
	String exception = "";

	if (StringUtils.isEmpty(databaseType)) {
		status = "error";
		message = "数据库类型不允许为空!";
	} else if (StringUtils.isEmpty(databaseHost)) {
		status = "error";
		message = "数据库主机不允许为空!";
	} else if (StringUtils.isEmpty(databasePort)) {
		status = "error";
		message = "数据库端口不允许为空!";
	} else if (StringUtils.isEmpty(databaseUsername)) {
		status = "error";
		message = "数据库用户名不允许为空!";
	} else if (StringUtils.isEmpty(databaseName)) {
		status = "error";
		message = "数据库名称不允许为空!";
	} else if (StringUtils.isEmpty(isInitializeDemo)) {
		status = "error";
		message = "初始化DEMO数据参数错误!";
	}

	String jdbcUrl = null;
	File sqlFile = null;
	Integer databaseMajorVersion = null;
	Integer databaseMinorVersion = null;

	if (status.equals("success")) {
		if (databaseType.equalsIgnoreCase("mysql")) {
			Connection connection = null;
			try {
				jdbcUrl = "jdbc:mysql://" + databaseHost + ":" + databasePort + "/" + databaseName + "?useUnicode=true&characterEncoding=" + DATABASE_ENCODING;
				connection = DriverManager.getConnection(jdbcUrl, databaseUsername, databasePassword);
			} catch (SQLException e) {
				jdbcUrl = "jdbc:mysql://" + databaseHost + ":" + databasePort + "/" + databaseName + "?useUnicode=true";
			} finally {
				try {
					if (connection != null) {
						connection.close();
						connection = null;
					}
				} catch (SQLException e) {
				}
			}
			sqlFile = new File(rootPath + "/install/data/mysql/demo.sql");
		} else if (databaseType.equalsIgnoreCase("sqlserver")) {
			jdbcUrl = "jdbc:sqlserver://" + databaseHost + ":" + databasePort + ";DatabaseName=" + databaseName;
			sqlFile = new File(rootPath + "/install/data/sqlserver/demo.sql");
		} else if (databaseType.equalsIgnoreCase("oracle")) {
			jdbcUrl = "jdbc:oracle:thin:@" + databaseHost + ":" + databasePort + ":" + databaseName;
			sqlFile = new File(rootPath + "/install/data/oracle/demo.sql");
		} else {
			status = "error";
			message = "参数错误!";
		}
	}
	
	if (status.equals("success") && (sqlFile == null || !sqlFile.exists())) {
		status = "error";
		message = "DEMO.SQL文件不存在!";
	}
	
	if (status.equals("success")) {
		Connection connection = null;
		try {
			connection = DriverManager.getConnection(jdbcUrl, databaseUsername, databasePassword);
			DatabaseMetaData databaseMetaData = connection.getMetaData();
			databaseMajorVersion = databaseMetaData.getDatabaseMajorVersion();
			databaseMinorVersion = databaseMetaData.getDatabaseMinorVersion();
		} catch (SQLException e) {
			status = "error";
			message = "JDBC执行错误!";
			exception = stackToString(e);
		} finally {
			try {
				if (connection != null) {
					connection.close();
					connection = null;
				}
			} catch (SQLException e) {
				status = "error";
				message = "JDBC执行错误!";
				exception = stackToString(e);
			}
		}
	}

	if (status.equals("success")) {
		Connection connection = null;
		Statement statement = null;
		String currentSQL = null;

		try {
			connection = DriverManager.getConnection(jdbcUrl, databaseUsername, databasePassword);
			connection.setAutoCommit(false);
			statement = connection.createStatement();
			
			Map<String, Object> model = new HashMap<String, Object>();
			model.put("base", request.getContextPath());
			model.put("demoImageUrl", DEMO_IMAGE_URL);
			
			if (databaseType.equalsIgnoreCase("mysql")) {
				String bit0 = null;
				String bit1 = null;
				if (databaseMajorVersion < 5) {
					bit0 = "'0'";
					bit1 = "'1'";
				} else {
					bit0 = "b'0'";
					bit1 = "b'1'";
				}
				model.put("bit0", bit0);
				model.put("bit1", bit1);
			}
			Calendar calendar = DateUtils.toCalendar(new Date());
			calendar.set(Calendar.HOUR_OF_DAY, calendar.getActualMinimum(Calendar.HOUR_OF_DAY));
			calendar.set(Calendar.MINUTE, calendar.getActualMinimum(Calendar.MINUTE));
			calendar.set(Calendar.SECOND, calendar.getActualMinimum(Calendar.SECOND));
			int i = 0;
			for (String line : FileUtils.readLines(sqlFile, "utf-8")) {
				if (StringUtils.isNotBlank(line) && !StringUtils.startsWith(line, "--")) {
					model.put("date", DateUtils.addSeconds(calendar.getTime(), i++));
					currentSQL = FreemarkerUtils.process(line, model);
					statement.executeUpdate(currentSQL);
				}
			}
			connection.commit();
			currentSQL = null;
		} catch (SQLException e) {
			status = "error";
			message = "JDBC执行错误!";
			exception = stackToString(e);
			if (currentSQL != null) {
				exception = "SQL: " + currentSQL + "<br />" + exception;
			}
		} catch (IOException e) {
			status = "error";
			message = "DEMO.SQL文件读取失败!";
			exception = stackToString(e);
		} finally {
			try {
				if (statement != null) {
					statement.close();
					statement = null;
				}
				if (connection != null) {
					connection.close();
					connection = null;
				}
			} catch (SQLException e) {
				status = "error";
				message = "JDBC执行错误!";
				exception = stackToString(e);
			}
		}
	}

	Map<String, String> data = new HashMap<String, String>();
	data.put("status", status);
	data.put("message", message);
	data.put("exception", exception);
	JsonUtils.writeValue(response.getWriter(), data);
%>