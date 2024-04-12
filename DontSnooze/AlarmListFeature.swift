import ComposableArchitecture
import SwiftUI

@Reducer
struct AlarmsList {
  @Reducer(state: .equatable)
  enum Destination {
    case add(AlarmForm)
    case alert(AlertState<Alert>)

    @CasePathable
    enum Alert {
      case confirmLoadMockData
    }
  }

  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var alarms: IdentifiedArrayOf<Alarm> = []

    init(destination: Destination.State? = nil) {
      self.destination = destination

      do {
        @Dependency(\.dataManager.load) var load
        self.alarms = try JSONDecoder().decode(IdentifiedArray.self, from: load(.alarms))
      } catch is DecodingError {
        self.destination = .alert(.dataFailedToLoad)
      } catch {
      }
      
      self.alarms = [.mock, .mock2]
    }
  }

  enum Action {
    case addAlarmButtonTapped
    case confirmAddAlarmButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case dismissAddAlarmButtonTapped
    case onDelete(IndexSet)
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addAlarmButtonTapped:
        state.destination = .add(AlarmForm.State(alarm: Alarm(id: self.uuid())))
        return .none

      case .confirmAddAlarmButtonTapped:
        guard case let .some(.add(editState)) = state.destination
        else { return .none }
        var alarm = editState.alarm
//        syncUp.attendees.removeAll { attendee in
//          attendee.name.allSatisfy(\.isWhitespace)
//        }
//        if syncUp.attendees.isEmpty {
//          syncUp.attendees.append(
//            editState.syncUp.attendees.first
//              ?? Attendee(id: Attendee.ID(self.uuid()))
//          )
//        }
        state.alarms.append(alarm)
        state.destination = nil
        return .none

      case .destination(.presented(.alert(.confirmLoadMockData))):
        state.alarms = [
//          .mock,
//          .designMock,
//          .engineeringMock,
        ]
        return .none

      case .destination:
        return .none

      case .dismissAddAlarmButtonTapped:
        state.destination = nil
        return .none

      case let .onDelete(indexSet):
        state.alarms.remove(atOffsets: indexSet)
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

struct AlarmsListView: View {
  @Bindable var store: StoreOf<AlarmsList>

  var body: some View {
    List {
      ForEach(store.alarms) { alarm in
        NavigationLink(
          state: AppFeature.Path.State.form(AlarmForm.State(alarm: alarm))
        ) {
          CardView(alarm: Store(initialState: AlarmForm.State(alarm: alarm)) {
            AlarmForm()
          })
        }
        .listRowBackground(Color.white)
        //.listRowBackground(syncUp.theme.mainColor)
      }
      .onDelete { indexSet in
        store.send(.onDelete(indexSet))
      }
    }
    .toolbar {
      Button {
        store.send(.addAlarmButtonTapped)
      } label: {
        Image(systemName: "plus")
      }
    }
    .navigationTitle("Alarm(s)")
    .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    .sheet(item: $store.scope(state: \.destination?.add, action: \.destination.add)) { store in
      NavigationStack {
        AlarmFormView(store: store)
          .navigationTitle("New alarm")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Dismiss") {
                self.store.send(.dismissAddAlarmButtonTapped)
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Add") {
                self.store.send(.confirmAddAlarmButtonTapped)
              }
            }
          }
      }
    }
  }
}

extension AlertState where Action == AlarmsList.Destination.Alert {
  static let dataFailedToLoad = Self {
    TextState("Data failed to load")
  } actions: {
    ButtonState(action: .send(.confirmLoadMockData, animation: .default)) {
      TextState("Yes")
    }
    ButtonState(role: .cancel) {
      TextState("No")
    }
  } message: {
    TextState(
      """
      Unfortunately your past data failed to load. Would you like to load some mock data to play \
      around with?
      """
    )
  }
}

struct CardView: View {
  @Bindable var store: StoreOf<AlarmForm>
  
  func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading) {
        Text(formatDate(store.alarm.time))
          .font(.title)
        Text(store.alarm.title)
          .font(.subheadline)
      }
      Toggle("", isOn: $store.alarm.isEnabled)
    }
    .padding()
    //.foregroundColor(self.syncUp.theme.accentColor)
    .foregroundColor(.black)
  }
}

struct TrailingIconLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.title
      configuration.icon
    }
  }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
  static var trailingIcon: Self { Self() }
}

#Preview {
  AlarmsListView(
    store: Store(initialState: AlarmsList.State()) {
      AlarmsList()
    } withDependencies: {
      $0.dataManager.load = { @Sendable _ in
        try JSONEncoder().encode([
          Alarm.mock,
          .mock2,
        ])
      }
    }
  )
}

//#Preview("Load data failure") {
//  SyncUpsListView(
//    store: Store(initialState: SyncUpsList.State()) {
//      SyncUpsList()
//    } withDependencies: {
//      $0.dataManager = .mock(initialData: Data("!@#$% bad data ^&*()".utf8))
//    }
//  )
//  .previewDisplayName("Load data failure")
//}
//
//#Preview("Card") {
//  CardView(
//    alarm: Alarm(id: UUID())
//  )
//}
