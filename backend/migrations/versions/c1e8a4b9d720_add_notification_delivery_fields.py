"""add notification delivery lifecycle fields

Revision ID: c1e8a4b9d720
Revises: b7d4e2c9a6f0
Create Date: 2026-06-24 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c1e8a4b9d720'
down_revision = 'b7d4e2c9a6f0'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('notifications') as batch_op:
        batch_op.add_column(sa.Column('delivery_status', sa.String(length=20), nullable=False, server_default='pending'))
        batch_op.add_column(sa.Column('delivery_channel', sa.String(length=20), nullable=True))
        batch_op.add_column(sa.Column('delivery_attempts', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('last_attempt_at', sa.Float(), nullable=True))
        batch_op.add_column(sa.Column('provider_ref', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('failure_reason', sa.String(length=200), nullable=True))


def downgrade():
    with op.batch_alter_table('notifications') as batch_op:
        batch_op.drop_column('failure_reason')
        batch_op.drop_column('provider_ref')
        batch_op.drop_column('last_attempt_at')
        batch_op.drop_column('delivery_attempts')
        batch_op.drop_column('delivery_channel')
        batch_op.drop_column('delivery_status')
