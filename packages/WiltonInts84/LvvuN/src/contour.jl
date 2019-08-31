struct IntegrationPath{T,P}
  center::P #
  inner_radius::T
  outer_radius::T
  segments::Vector{Tuple{P,P}}
  arcs::Vector{Tuple{P,P,Int}}
  circles::Vector{Int}
  normal::P
  height::T #
  projected_center::P
  plane_inner_radius::T
  plane_outer_radius::T
end

const CLOCKWISE = -1
const COUNTERCLOCKWISE = +1

function contour(p1, p2, p3, center)

    Vertex = typeof(p1)
    segments = Tuple{Vertex,Vertex}[
        (p1,p2),
        (p2,p3),
        (p3,p1),
    ]
    arcs = Tuple{Vertex,Vertex,Int}[]
    circles = Int[]

    normal = (p1-p3) × (p2-p3)
    normal /= norm(normal)

    height = (center - p1) ⋅ normal
    plane_center = center - height * normal

    inner_radius = outer_radius = zero(eltype(p1))
    plane_inner_radius = plane_outer_radius = zero(eltype(p1))

    IntegrationPath(
      center,
      inner_radius,
      outer_radius,
      segments,
      arcs,
      circles,
      normal,
      height,
      plane_center,
      plane_inner_radius,
      plane_outer_radius,
    )
end


mutable struct WorkSpace{V}
  inner_in::Vector{V}
  inner_out::Vector{V}
  outer_in::Vector{V}
  outer_out::Vector{V}
  inner_in_edge::Vector{Int}
  inner_out_edge::Vector{Int}
  outer_in_edge::Vector{Int}
  outer_out_edge::Vector{Int}
  segments::Vector{Tuple{V,V}}
  arcs::Vector{Tuple{V,V,Int}}
  circles::Vector{Int}
end


function contour(p1, p2, p3, center, inner_radius, outer_radius)
  ws = workspace(typeof(p1))
  contour!(p1, p2, p3, center, inner_radius, outer_radius, ws)
end

function workspace(V::Type)
  ws = WorkSpace(
    Vector{V}(undef,3), Vector{V}(undef,3), Vector{V}(undef,3), Vector{V}(undef,3),
    Vector{Int}(undef,3), Vector{Int}(undef,3), Vector{Int}(undef,3), Vector{Int}(undef,3),
    Vector{Tuple{V,V}}(undef,0), Vector{Tuple{V,V,Int}}(undef,0), Vector{Int}(undef,0)
  )
  sizehint!(ws.segments,8)
  sizehint!(ws.arcs,8)
  sizehint!(ws.circles,2)
  return ws
end


function contour!(p1, p2, p3, center, inner_radius, outer_radius, ws)

  deci = eltype(p1)
  Vertex = typeof(p1)

  #t_inner = zeros(deci,2)
  #t_outer = zeros(deci,2)

  #inner_in  = Vector{Vertex}(3)
  #inner_out = Vector{Vertex}(3)
  #outer_in  = Vector{Vertex}(3)
  #outer_out = Vector{Vertex}(3)

  #inner_in_edge  = zeros(Int,3)
  #inner_out_edge = zeros(Int,3)
  #outer_in_edge  = zeros(Int,3)
  #outer_out_edge = zeros(Int,3)
  fill!(ws.inner_in_edge, 0)
  fill!(ws.inner_out_edge, 0)
  fill!(ws.outer_in_edge, 0)
  fill!(ws.outer_out_edge, 0)

  is_not_empty = number_of_segments = number_of_arcs = number_of_circles = 0
  inner = outer = inner_inc = inner_outc = outer_inc = outer_outc = 0

  # centra en stralen berekenen
  inner_radius = (inner_radius > 0.0) ? inner_radius : 0.0
  outer_radius = (outer_radius > 0.0) ? outer_radius : 0.0

  # Vertex normal = f.normal()
  normal = (p1-p3) × (p2-p3)
  normal /= norm(normal)

  d = (center - p1) ⋅ normal
  absd = abs(d)
  plane_center = center - dot(normal, center - p1) * normal

  discr = inner_radius*inner_radius - d * d
  plane_inner_radius = (discr > 0.0) ? sqrt(discr) : -1.0
  discr = outer_radius*outer_radius - d * d
  plane_outer_radius = (discr > 0.0) ? sqrt(discr) : -1.0

  #segments = Vector{Tuple{Vertex,Vertex}}()
  #arcs = Vector{Tuple{Vertex,Vertex,Int}}()
  #circles = Vector{Int}()
  resize!(ws.segments,0)
  resize!(ws.arcs,0)
  resize!(ws.circles,0)

  # loop over de edges om segmenten te vinden
  first = zero(Vertex)
  last  = zero(Vertex)
  F = (p1,p2,p3)
  L = (p2,p3,p1)
  for i in 1:3
    first, last = F[i], L[i]
    z_inner, t_inner = incidenceLineWithSphere(center, first, last, inner_radius)
    z_outer, t_outer = incidenceLineWithSphere(center, first, last, outer_radius)
    code = 10 * z_outer + z_inner

    if code == 00
      d1 = norm(first - center)
      d2 = norm(last - center)
      D = 0.5 * (d1 + d2)
      if !(D < inner_radius || D > outer_radius)
        push!(ws.segments, (first,last))
      end

    elseif code == 01
      t1 = t_inner[1]
      v1 = (1-t1) * first + t1 * last
      d1 = norm(first - center)
      d2 = norm(last - center)
      if d1 > d2
        push!(ws.segments, (first, v1))
        inner_inc += 1
        ws.inner_in[inner_inc] = v1
        ws.inner_in_edge[inner_inc] = i
      else
        push!(ws.segments, (v1, last))
        inner_outc += 1
        ws.inner_out[inner_outc] = v1
        ws.inner_out_edge[inner_outc] = i
      end

    elseif code == 02
      t1 = t_inner[1]
      t2 = t_inner[2]
      v1 = (1-t1) * first +  t1 * last
      inner_inc += 1
      ws.inner_in[inner_inc] = v1
      ws.inner_in_edge[inner_inc] = i
      v2 = (1-t2) * first + t2 * last
      inner_outc += 1
      ws.inner_out[inner_outc] = v2
      ws.inner_out_edge[inner_outc] = i
      push!(ws.segments, (first,v1))
      push!(ws.segments, (v2,last))

    elseif code == 10
      t1 = t_outer[1]
      v1 = (1-t1) * first +  t1 * last
      d1 = norm(first - center)
      d2 = norm(last - center)
      if d1 < d2
          push!(ws.segments, (first, v1))
          outer_inc += 1
          ws.outer_in[outer_inc] = v1
          ws.outer_in_edge[outer_inc] = i
      else
          push!(ws.segments, (v1, last))
          outer_outc += 1
          ws.outer_out[outer_outc] = v1
          ws.outer_out_edge[outer_outc] = i
      end


    elseif code == 11
      t1 = t_inner[1]
      t2 = t_outer[1]
      v1 = (1-t1) * first + t1 * last
      v2 = (1-t2) * first + t2 * last
      if t1 < t2
        push!(ws.segments, (v1, v2))
        inner_outc += 1
        ws.inner_out[inner_outc] = v1
        ws.inner_out_edge[inner_outc] = i
        outer_inc += 1
        ws.outer_in[outer_inc] = v2
        ws.outer_in_edge[outer_inc] = i
      else
        push!(ws.segments, (v2, v1))
        inner_inc += 1
        ws.inner_in[inner_inc] = v1
        ws.inner_in_edge[inner_inc] = i
        outer_outc += 1
        ws.outer_out[outer_outc] = v2
        ws.outer_out_edge[outer_outc] = i
      end

    elseif code == 12
      t1 = t_inner[1]
      t2 = t_inner[2]
      t3 = t_outer[1]
      v1 = (1-t1) * first + t1 * last
      v2 = (1-t2) * first + t2 * last
      v3 = (1-t3) * first + t3 * last
      if t1 < t3
        push!(ws.segments, (first, v1))
        push!(ws.segments, (v2, v3))
        inner_inc += 1
        ws.inner_in[inner_inc] = v1
        ws.inner_in_edge[inner_inc] = i
        inner_outc += 1
        ws.inner_out[inner_outc] = v2
        ws.inner_out_edge[inner_outc] = i
        outer_inc += 1
        ws.outer_in[outer_inc] = v3
        ws.outer_in_edge[outer_inc] = i
      else
        push!(ws.segments, (v3, v1))
        push!(ws.segments, (v2, last))
        inner_inc += 1
        ws.inner_in[inner_inc] = v1
        ws.inner_in_edge[inner_inc] = i
        inner_outc += 1
        ws.inner_out[inner_outc] = v2
        ws.inner_out_edge[inner_outc] = i
        outer_outc += 1
        ws.outer_out[outer_outc] = v3
        ws.outer_out_edge[outer_outc] = i
      end

    elseif code == 20
      t1 = t_outer[1]
      t2 = t_outer[2]
      v1 = (1-t1) * first + t1 * last
      outer_outc += 1
      ws.outer_out[outer_outc] = v1
      ws.outer_out_edge[outer_outc] = i
      v2 = (1-t2) * first + t2 * last
      outer_inc += 1
      ws.outer_in[outer_inc] = v2
      ws.outer_in_edge[outer_inc] = i
      push!(ws.segments, (v1, v2))

    elseif code == 22
      t1 = t_inner[1]
      t2 = t_inner[2]
      t3 = t_outer[1]
      t4 = t_outer[2]
      v1 = (1-t1) * first + t1 * last
      v2 = (1-t2) * first + t2 * last
      v3 = (1-t3) * first + t3 * last
      v4 = (1-t4) * first + t4 * last
      inner_inc += 1
      ws.inner_in[inner_inc] = v1
      ws.inner_in_edge[inner_inc] = i
      inner_outc += 1
      ws.inner_out[inner_outc] = v2
      ws.inner_out_edge[inner_outc] = i
      outer_outc += 1
      ws.outer_out[outer_outc] = v3
      ws.outer_out_edge[outer_outc] = i
      outer_inc += 1
      ws.outer_in[outer_inc] = v4
      ws.outer_in_edge[outer_inc] = i
      push!(ws.segments, (v3, v1))
      push!(ws.segments, (v2, v4))
    end

    #@show code

  end # end for i

  # bereken het aantal snijpunten met de twee cirkels
  inner = inner_inc + inner_outc
  outer = outer_inc + outer_outc

  #@show inner_inc inner_outc
  #@show outer_inc outer_outc

  try
  @assert inner_inc == inner_outc
  @assert outer_inc == outer_outc
  catch
      # @show inner_inc inner_outc
      # @show outer_inc outer_outc
      # @show p1, p2, p3
      # @show center, inner_radius, outer_radius
      error("inconsistent contour construction!")
  end

  # construct the inner arcs
  if inner == 0
  elseif inner == 2
    push!(ws.arcs, (ws.inner_in[1], ws.inner_out[1], CLOCKWISE))
  elseif inner == 4
    if ws.inner_in_edge[1] == ws.inner_out_edge[1]
      push!(ws.arcs, (ws.inner_in[1],ws.inner_out[2],CLOCKWISE))
      push!(ws.arcs, (ws.inner_in[2], ws.inner_out[1], CLOCKWISE))
    elseif ws.inner_in_edge[1] == ws.inner_out_edge[2]
      push!(ws.arcs, (ws.inner_in[1],ws.inner_out[1],CLOCKWISE))
      push!(ws.arcs, (ws.inner_in[2], ws.inner_out[2],CLOCKWISE))
    else
      ed1 = ws.inner_in_edge[1]
      ed2 = mod1(ed1-1, 3)
      if ws.inner_out_edge[1] == ed2
        # This branch -I think- cannot be reached
        push!(ws.arcs, (ws.inner_in[1], ws.inner_out[1], CLOCKWISE))
        push!(ws.arcs, (ws.inner_in[2], ws.inner_out[2], CLOCKWISE))
      else
        push!(ws.arcs, (ws.inner_in[1], ws.inner_out[2], CLOCKWISE))
        push!(ws.arcs, (ws.inner_in[2], ws.inner_out[1], CLOCKWISE))
      end
    end
  elseif inner == 6
    for i in 1:3
      ed1 = ws.inner_in_edge[i]
      ed2 = mod1(ed1-1,3)
      for j in 1:3
        if ed2 == ws.inner_out_edge[j]
          push!(ws.arcs, (ws.inner_in[i], ws.inner_out[j], CLOCKWISE))
        end
      end
    end
  end

  # construct the outer arcs
  if outer == 0
  elseif outer == 2
    push!(ws.arcs, (ws.outer_in[1], ws.outer_out[1], COUNTERCLOCKWISE))
  elseif outer == 4
    if ws.outer_in_edge[1] == ws.outer_out_edge[1]
      push!(ws.arcs, (ws.outer_in[1], ws.outer_out[2], COUNTERCLOCKWISE))
      push!(ws.arcs, (ws.outer_in[2], ws.outer_out[1], COUNTERCLOCKWISE))
    elseif ws.outer_in_edge[1] == ws.outer_out_edge[2]
      # This branch cannot be reached
      push!(ws.arcs, (ws.outer_in[1], ws.outer_out[1], COUNTERCLOCKWISE))
      push!(ws.arcs, (ws.outer_in[2], ws.outer_out[2], COUNTERCLOCKWISE))
    else
      ed1 = ws.outer_in_edge[1]
      ed2 = mod1(ed1+1,3)
      if ws.outer_out_edge[1] == ed2
        push!(ws.arcs, (ws.outer_in[1], ws.outer_out[1], COUNTERCLOCKWISE))
        push!(ws.arcs, (ws.outer_in[2], ws.outer_out[2], COUNTERCLOCKWISE))
      else
        push!(ws.arcs, (ws.outer_in[1], ws.outer_out[2], COUNTERCLOCKWISE))
        push!(ws.arcs, (ws.outer_in[2], ws.outer_out[1], COUNTERCLOCKWISE))
      end
    end
  elseif outer == 6
    for i in 1:3
      ed1 = ws.outer_in_edge[i]
      ed2 = mod1(ed1+1, 3)
      for j in 1:3
        if ed2==ws.outer_out_edge[j]
          push!(ws.arcs, (ws.outer_in[i], ws.outer_out[j], COUNTERCLOCKWISE))
        end
      end
    end
  end

  # construct the circle contributions
  if inside(plane_center,p1,p2,p3,normal)
    d1 = distancetoline(plane_center, p1, p2)
    d2 = distancetoline(plane_center, p2, p3)
    d3 = distancetoline(plane_center, p3, p1)
    if d1>plane_inner_radius && d2>plane_inner_radius && d3>plane_inner_radius && plane_inner_radius>0
      push!(ws.circles, CLOCKWISE)
    end
    if d1>plane_outer_radius && d2>plane_outer_radius && d3>plane_outer_radius && plane_outer_radius>0
      push!(ws.circles, COUNTERCLOCKWISE)
    end
  end

  IntegrationPath(
    center,
    inner_radius,
    outer_radius,
    ws.segments,
    ws.arcs,
    ws.circles,
    normal,
    d,
    plane_center,
    plane_inner_radius,
    plane_outer_radius
  )
end


function inside(v,p1,p2,p3,n)
  dot((p2-p1)×(v-p1), n) <= 0 && return false
  dot((p3-p2)×(v-p2), n) <= 0 && return false
  dot((p1-p3)×(v-p3), n) <= 0 && return false
  return true
end


function distancetoline(p,a,b)
  t = b-a
  t /= norm(t)
  u = p-a
  norm(u - dot(u,t)*t)
end


"""
  r, t = incidenceLineWithSphere(v, first, last, r)

Returns the number of crossings and their barycentric coordinates for a circle
with center v and radius r and a segment [a,b]. If the circle is tangent to the
segment, zero crossings are reported.
"""
function incidenceLineWithSphere(v, first, last, r)

    ϵ = eps(typeof(r)) * 1e3
    z = zero(typeof(r))

    r<=0 && return 0, (z,z)

    a = dot((last - first) , (last - first))
    b =  2 * dot( (first - v) , (last - first))
    c = dot((first - v) , (first - v)) - r*r
    d = b * b - 4 * a * c
    d < ϵ && return 0, (z,z)
    f = sqrt(d)

    t1 = (-b - f) / (2 * a)
    p1 = (0 < t1 <= 1)

    t2 = (-b + f) / (2 * a)
    p2 = (0 < t2 <= 1)

    if p1
        if p2
            return 2, (t1,t2)
        else
            return 1, (t1,z)
        end
    else
        if p2
            return 1, (t2,z)
        else
            return 0, (z,z)
        end
    end

    return 0, (z,z)
end
