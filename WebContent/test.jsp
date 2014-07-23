<!DOCTYPE html>
<html>
<head lang="en">
    <meta charset="UTF-8">
    <title>awesome bootstrap checkbox demo</title>
    <link rel="stylesheet" href="checkBox/css/bootstrap.css"/>
    <link rel="stylesheet" href="checkBox/css/font-awesome.css"/>
    <link rel="stylesheet" href="checkBox/css/awesome-bootstrap-checkbox.css"/>
    <link rel="stylesheet" href="checkBox/css/build.css"/>
</head>
<body>
<div class="container">
    <h2>Checkboxes</h2>
    <form >
        <div class="row">

            <div class="col-md-4">
                <fieldset>
                    <legend>
                        Circled
                    </legend>
                    <p>
                        <code>.checkbox-circle</code> for roundness.
                    </p>
                    <div class="checkbox checkbox-info checkbox-circle">
                        <input id="checkbox7" type="checkbox">
                        <label for="checkbox7">
                            Simply Rounded
                        </label>
                    </div>
                    <div class="checkbox checkbox-info checkbox-circle">
                        <input id="checkbox8" type="checkbox" checked>
                        <label for="checkbox8">
                            Me too
                        </label>
                    </div>
                </fieldset>
            </div>

        </div>
    </form>
    

    <h2>Radios</h2>
    <form role="form">
        <div class="row">
            <div class="col-md-4">
                <fieldset>
                    <legend>
                        Basic
                    </legend>
                    <p>
                        Supports bootstrap brand colors: <code>.radio-primary</code>, <code>.radio-danger</code> etc.
                    </p>
                    <div class="row">
                        <div class="col-sm-6">
                            <div class="radio">
                                <input type="radio" name="radio1" id="radio1" value="option1" checked>
                                <label for="radio1">
                                    Small
                                </label>
                            </div>
                            <div class="radio">
                                <input type="radio" name="radio1" id="radio2" value="option2">
                                <label for="radio2">
                                    Big
                                </label>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="radio radio-danger">
                                <input type="radio" name="radio2" id="radio3" value="option1">
                                <label for="radio3">
                                    Next
                                </label>
                            </div>
                            <div class="radio radio-danger">
                                <input type="radio" name="radio2" id="radio4" value="option2" checked>
                                <label for="radio4">
                                    One
                                </label>
                            </div>
                        </div>
                    </div>
                </fieldset>
            </div>
            
    </form>
</div>
</body>
</html>