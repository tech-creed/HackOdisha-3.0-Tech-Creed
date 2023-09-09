const express = require("express");

const router = express.Router();

router.get("/dashboard-in",(req,res)=>{
    res.render('individualDashboard')
})

router.get("/dashboard-gov",(req,res)=>{
    res.render('GovernmentDashboard')
})

module.exports = router;