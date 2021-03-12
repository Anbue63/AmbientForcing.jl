using AmbientForcing
using PowerDynamics, Distributions

# lets create a small test power grid with three nodes
line_list = []
append!(line_list, [StaticLine(from = 1, to = 2, Y = -1im / 0.02 + 4)])
append!(line_list, [StaticLine(from = 1, to = 3, Y = -1im / 0.02 + 4)])

node_list = []
append!(node_list, [SlackAlgebraic(U = 1, Y_n = 0)])
append!(node_list, [FourthOrderEq(H = 3.318, P = -0.6337, D = 0.1, Ω = 50, E_f = 0.5, T_d_dash = 0.1,  T_q_dash = 8.690,X_d_dash = 0.111,  X_q_dash = 0.103, X_d = 0.1, X_q = 0.6)])
append!(node_list, [PQAlgebraic(P = -0.6337, Q = 0.0)]) # This is our constraint

pg = PowerGrid(node_list, line_list)
rpg = rhs(pg) # using the rigth hand side as our ODEFunction

g = constraint_equations(rpg) # the constaint equation of the power grid

# the op is a fixed point and natrully lies on the manifold
# it can be used as the initial condition for our differential equation
op = find_operationpoint(pg) 

g(op.vec) # g(op) ≈ 0, this means that the constraint is fulfilled

# Lets generate a random vector from the ambient space
# first we want to perturb all variables in the grid

Frand = random_force(rpg, [0.0,1], Uniform)

z_new = ambient_forcing(rpg, op.vec, 2.0, Frand) # Our new valid inital condition
g(z_new) # fulfills the constraints :-)

## Next: lets perturb just the voltage at node 2!

# gettng the index of the real and imaginary part of the voltage
idx = idx_exclusive(rpg, ["u_r_2", "u_i_2"]) 
# genrate a vector only with non-vanishing componats the voltage at node 2
Frand = random_force(rpg, [0.0, 1.0], Uniform, idx) 

z_new = ambient_forcing(rpg, op.vec, 2.0, Frand) # solve the differential equation
g(z_new) # the constraint remains fulfilled

# it is also possible to perturb the variable using different distributions:
# In typically SNBS the angle θ and ω are sampled from different boxes
idx = idx_exclusive(rpg, ["u_r_2", "u_i_2", "θ_2", "ω_2"])
τ = 2.0 # the integration time

# when you want to sample eg. the angle θ from a box of [0, 2π] 
# you have to make sure
# to devide the distribution argument by the integration time τ
dist_vec = [[0,1], [0, 2], [0, 2π] ./τ, [-5, 5] ./τ]

# then everything works as beforehand only each variable 
# is sampled from a different box
Frand = Frand = random_force(rpg, dist_vec, Uniform, idx)
z_new = ambient_forcing(rpg, op.vec, τ, Frand) # solve the differential equation
g(z_new)