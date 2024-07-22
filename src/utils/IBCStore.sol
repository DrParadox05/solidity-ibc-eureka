// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IIBCStore } from "./IIBCStore.sol";
import { IICS26RouterMsgs } from "../msgs/IICS26RouterMsgs.sol";
import { ICS24Host } from "./ICS24Host.sol";

abstract contract IBCStore is IIBCStore {
    // Commitments
    // keccak256(IBC-compatible-store-path) => keccak256(IBC-compatible-commitment)
    mapping(bytes32 => bytes32) internal commitments;

    // Next sequence sends for a given port and channel pair
    mapping(string => mapping(string => uint32)) internal nextSequenceSends;

    // @notice Gets the commitment for a given path.
    function getCommitment(bytes32 hashedPath) public view returns (bytes32) {
        return commitments[hashedPath];
    }

    // @notice Get the next sequence to send for a given port and channel pair.
    function getNextSequenceSend(string calldata portId, string calldata channelId) public view returns (uint32) {
        return nextSequenceSends[portId][channelId];
    }

    // @notice Gets and increments the next sequence to send for a given port and channel pair.
    function nextSequenceSend(string calldata portId, string calldata channelId) internal returns (uint32) {
        uint32 seq = nextSequenceSends[portId][channelId] + 1;
        nextSequenceSends[portId][channelId] = seq;
        return seq;
    }

    // @notice Commits a packet
    // @param packet The packet to commit
    // @custom:spec
    // https://github.com/cosmos/ibc-go/blob/2b40562bcd59ce820ddd7d6732940728487cf94e/modules/core/04-channel/types/packet.go#L38
    function commitPacket(IICS26RouterMsgs.Packet calldata packet) internal {
        bytes32 path = ICS24Host.packetCommitmentKeyCalldata(packet.sourcePort, packet.sourceChannel, packet.sequence);
        require(commitments[path] == 0, "commitment exists");

        bytes32 commitment = ICS24Host.packetCommitmentBytes32(packet);
        commitments[path] = commitment;
    }

    // @notice Deletes a packet commitment
    // @param packet The packet whose commitment to delete
    function deletePacketCommitment(IICS26RouterMsgs.Packet calldata packet) internal {
        bytes32 path = ICS24Host.packetCommitmentKeyCalldata(packet.sourcePort, packet.sourceChannel, packet.sequence);
        require(commitments[path] != 0, "commitment does not exist");

        delete commitments[path];
    }

    // @notice Sets a packet receipt
    function setPacketReceipt(IICS26RouterMsgs.Packet calldata packet) internal {
        bytes32 path =
            ICS24Host.packetReceiptCommitmentKeyCalldata(packet.destPort, packet.destChannel, packet.sequence);
        require(commitments[path] == 0, "receipt exists");

        commitments[path] = ICS24Host.PACKET_RECEIPT_SUCCESSFUL_KECCAK256;
    }

    // @notice Commits a packet acknowledgement
    function commitPacketAcknowledgement(IICS26RouterMsgs.Packet calldata packet, bytes calldata ack) internal {
        bytes32 path =
            ICS24Host.packetAcknowledgementCommitmentKeyCalldata(packet.destPort, packet.destChannel, packet.sequence);
        require(commitments[path] == 0, "ack exists");

        bytes32 commitment = ICS24Host.packetAcknowledgementCommitmentBytes32(ack);
        commitments[path] = commitment;
    }
}