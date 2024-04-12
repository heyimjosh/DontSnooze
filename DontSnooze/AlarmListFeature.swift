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
    }
  }

  enum Action {
    case addSyncUpButtonTapped
    case confirmAddSyncUpButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case dismissAddSyncUpButtonTapped
    case onDelete(IndexSet)
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addSyncUpButtonTapped:
        //state.destination = .add(AlarmForm.State(alarm: Alarm(id: self.uui))
        return .none

      case .confirmAddSyncUpButtonTapped:
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

      case .dismissAddSyncUpButtonTapped:
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
          //state: AppFeature.Path.State.detail(SyncUpDetail.State(syncUp: syncUp))
          state: AppFeature.Path.State.form(AlarmForm.State(alarm: alarm))
        ) {
          CardView(alarm: alarm)
          
        }
        .listRowBackground(.blue)
        //.listRowBackground(syncUp.theme.mainColor)
      }
      .onDelete { indexSet in
        store.send(.onDelete(indexSet))
      }
    }
    .toolbar {
      Button {
        store.send(.addSyncUpButtonTapped)
      } label: {
        Image(systemName: "plus")
      }
    }
    .navigationTitle("Daily Sync-ups")
    .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    .sheet(item: $store.scope(state: \.destination?.add, action: \.destination.add)) { store in
      NavigationStack {
        AlarmFormView(store: store)
          .navigationTitle("New alarm")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Dismiss") {
                self.store.send(.dismissAddSyncUpButtonTapped)
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Add") {
                self.store.send(.confirmAddSyncUpButtonTapped)
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
  let alarm: Alarm

  var body: some View {
    VStack(alignment: .leading) {
      Text(self.alarm.title)
        .font(.headline)
      Spacer()
      HStack {
        //Label("\(self.syncUp.attendees.count)", systemImage: "person.3")
        Label("\(3)", systemImage: "person.3")
        Spacer()
        Label(4, systemImage: "clock")
        //          .labelStyle(.trailingIcon)
//        Label(self.syncUp.duration.formatted(.units()), systemImage: "clock")
//          .labelStyle(.trailingIcon)
      }
      .font(.caption)
    }
    .padding()
    //.foregroundColor(self.syncUp.theme.accentColor)
    .foregroundColor(.green)
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

//#Preview {
//  SyncUpsListView(
//    store: Store(initialState: SyncUpsList.State()) {
//      SyncUpsList()
//    } withDependencies: {
//      $0.dataManager.load = { @Sendable _ in
//        try JSONEncoder().encode([
//          SyncUp.mock,
//          .designMock,
//          .engineeringMock,
//        ])
//      }
//    }
//  )
//}

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
//    syncUp: SyncUp(
//      id: SyncUp.ID(),
//      attendees: [],
//      duration: .seconds(60),
//      meetings: [],
//      theme: .bubblegum,
//      title: "Point-Free Morning Sync"
//    )
//  )
//}