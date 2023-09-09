const express = require("express")
const cookieParser = require("cookie-parser")
const cors = require('cors')

const app = express()

app.use(cors())
app.use(express.static('public'))
app.use(express.json())
app.use(express.urlencoded({
  extended: true
}))
app.use(cookieParser())

const PORT = 5000;

app.set('view engine', 'ejs')

//Routes
const AuthenticationRoute = require('./routes/authRoutes.js')
const DashboardRoute = require('./routes/dashboardRoute.js')

app.use('/auth', AuthenticationRoute)
app.use('/', DashboardRoute)


app.get("/",(req,res)=>{
    res.render('index')
})

app.listen(PORT, () => console.log(`Server running on port: http://localhost:${PORT}`));