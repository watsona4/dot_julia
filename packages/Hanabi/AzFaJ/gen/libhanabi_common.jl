# Automatically generated using Clang.jl wrap_c


struct PyHanabiCard
    color::Cint
    rank::Cint
end

const pyhanabi_card_t = PyHanabiCard

struct PyHanabiCardKnowledge
    knowledge::Ptr{Cvoid}
end

const pyhanabi_card_knowledge_t = PyHanabiCardKnowledge

struct PyHanabiMove
    move::Ptr{Cvoid}
end

const pyhanabi_move_t = PyHanabiMove

struct PyHanabiHistoryItem
    item::Ptr{Cvoid}
end

const pyhanabi_history_item_t = PyHanabiHistoryItem

struct PyHanabiState
    state::Ptr{Cvoid}
end

const pyhanabi_state_t = PyHanabiState

struct PyHanabiGame
    game::Ptr{Cvoid}
end

const pyhanabi_game_t = PyHanabiGame

struct PyHanabiObservation
    observation::Ptr{Cvoid}
end

const pyhanabi_observation_t = PyHanabiObservation

struct PyHanabiObservationEncoder
    encoder::Ptr{Cvoid}
end

const pyhanabi_observation_encoder_t = PyHanabiObservationEncoder
