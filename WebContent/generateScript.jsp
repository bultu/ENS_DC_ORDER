<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1"%>
<%@taglib prefix="s" uri="/struts-tags"%>
<%@ page import="java.lang.*"%>

<!DOCTYPE html>
<html lang="en">

<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="">
<meta name="author" content="">
<link rel="shortcut icon" href="../../assets/ico/favicon.ico">

<title>Admin Console</title>

<script src="jquery/js/jquery-1.11.1.min.js"></script>
<link href="bootstrap/css/bootstrap.min.css" rel="stylesheet">
<link href="bootstrap/css/bootstrap.css" rel="stylesheet">
<link href="bootstrap/css/dashboard.css" rel="stylesheet">
<link href="bootstrap/css/datepicker.css" rel="stylesheet">



<script type="text/javascript">
	$(function() {

		$(".dropdown-menu li a").click(function() {
			$("#drpdwn").text($(this).text());
			$("#drpdwn").val($(this).text());
			$("#type").val($(this).text());
		});

	});

	// When the document is ready
	$(document).ready(function() {

		$('#datePicker').datepicker({

		});

	});
</script>

</head>

<body>

	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="container-fluid">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle" data-toggle="collapse"
					data-target=".navbar-collapse">
					<span class="sr-only">Toggle navigation</span> <span
						class="icon-bar"></span> <span class="icon-bar"></span> <span
						class="icon-bar"></span>
				</button>
				<a class="navbar-brand" href="#">Ensemble CSM</a>
			</div>
			<div class="navbar-collapse collapse">
				<ul class="nav navbar-nav navbar-right">

					<li class="dropdown"><a class="dropdown-toggle"
						data-toggle="dropdown" href="#"> <i
							class="glyphicon glyphicon-user"></i>ADMIN CONSOLE<span
							class="caret"></span></a>
						<ul id="g-account-menu" class="dropdown-menu">
							<li><a href="home.jsp">Home</a></li>
							<li><a href="#"><i class="glyphicon glyphicon-lock"></i>
									Logout</a></li>
						</ul></li>
				</ul>
			</div>
		</div>
	</div>

	<div class="container-fluid">
		<div class="row">
			<div class="col-sm-3 col-md-2 sidebar">
				<ul class="nav nav-sidebar">
					<li><a href="admin.jsp">Overview</a></li>
					<li class="active"><a href="generateScript.jsp">Generate
							Script</a></li>
					<li><a href="issueInput.jsp">Issue Input</a></li>
				</ul>

			</div>
			<div class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
				<h1 class="page-header">Generate Script</h1>


				<form class="form form-vertical" action="generateScript"
					id="submitScript">
					<div class="control-group">
						<label>Name</label>
						<div class="controls">
							<input type="text" class="form-control"
								placeholder="Developer Name" name="developerName">
						</div>
					</div>
					<div class="control-group">
						<label>File Name</label>
						<div class="controls">
							<input type="text" class="form-control"
								placeholder="Script File Name" name="fileName">

						</div>
					</div>

					<div class="control-group">
						<label>Date</label>
						<div class="controls">
							<input type="text" class="form-control"
								placeholder="Creation Date" name="date" id="datePicker">

						</div>
					</div>


					<div class="control-group" style="position: relative; top: 10px;">
						<!-- <label>Issue Type </label> -->
						<div class="btn-group">
							<button data-toggle="dropdown"
								class="btn btn-default dropdown-toggle form-control"
								name="drpdwn" id="drpdwn">
								Issue Type <span class="caret"></span>
							</button>
							<ul class="dropdown-menu">
								<li><a href="javascript:return false;">DC_ORDER</a></li>
								<li><a href="javascript:return false;">CANCEL_ORDER</a></li>
								<li><a href="javascript:return false;">OTHER</a></li>
							</ul>
						</div>
					</div>


					<input type="hidden" name="type" id="type" value="DC_ORDER">

					<div class="control-group">
						<label></label>
						<div class="controls">
							<button type="submit" class="btn btn-primary">Generate</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>


</body>

<!-- Add Javascript files in end of the file to make page load faster -->


<script src="bootstrap/js/bootstrap.min.js"></script>
<script src="bootstrap/js/bootstrap-datepicker.js"></script>
</html>
