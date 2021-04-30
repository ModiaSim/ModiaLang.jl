module RectifierSimulation

using TinyModia
using DifferentialEquations
using ModiaPlot

setLogMerge(false)

include("../models/Electric.jl")


# Sinusoidal voltage source
SineVoltage = OnePort | Model( V = 1.0u"V", f = 1.0u"Hz", equations = :[ v = V*sin(2*3.14*f*time) ] )

# Ideal diode
IdealDiode = OnePort | Model(
        Ron   = 1e-4,
        Goff  = 1e-4,
        s = Var(start = 0.0),
        equations = :[              
            closed = positive(s)   # closed = s > 0
            #closed = positive(instantiatedModel, 1, s, "s", _leq_mode)
            v = s*(if closed; Ron else 1    end)
            i = s*(if closed; 1   else Goff end)
        ]
    )


Rectifier = Model(
    R1 = Resistor | Map(R=1.0u"Ω"),
    R2 = Resistor | Map(R=1.0u"Ω"),    
    C = Capacitor | Map(C=1.0u"F", v=Var(init=0.0u"V")),
    D = IdealDiode,
    V = SineVoltage | Map(V=5.0u"V", f=1.5u"Hz"),
    ground = Ground,
    connect = :[
      (V.p , R1.p)
      (R1.n, D.p)
      (D.n , R2.p, C.p)
      (ground.p, R2.n, C.n, V.n)
    ]
)

model = @instantiateModel(Rectifier, log=true, logCode=true, logStateSelection=true)
@time simulate!(model, Tsit5(), stopTime = 3, nz = 1)
plot(model, ("R.v", "D.v", "V.v", "C.v"))

end