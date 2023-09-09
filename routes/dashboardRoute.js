const express = require("express");

const router = express.Router();

router.get("/dashboard-in",(req,res)=>{
    res.render('individualDashboard')
})

router.get("/dashboard-gov",(req,res)=>{
    res.render('GovernmentDashboard')
})

router.get("/document",(req,res)=>{
    res.render('document')
})

module.exports = router;